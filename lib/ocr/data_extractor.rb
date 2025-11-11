# frozen_string_literal: true

require "mini_magick"
require "pdf/reader"
require "rtesseract"
require "securerandom"
require "shellwords"
require "tmpdir"

module Ocr
  ##
  # DataExtractor handles PDF text extraction.
  # It can parse regular PDFs or scanned PDFs using OCR.
  #
  # @example Extract text from a PDF
  #   extractor = Ocr::DataExtractor.new("example.pdf")
  #   result = extractor.call
  #   if result["success"]
  #     puts result["raw_text"]
  #   else
  #     puts result["message"]
  #   end
  #
  class DataExtractor
    ##
    # Initializes a new DataExtractor.
    #
    # @param document [String, File, IO] Path to a PDF file, File object, or IO object.
    #
    def initialize(document)
      @document = document
    end

    ##
    # Main method to extract text from the PDF.
    #
    # @return [Hash] Result hash containing:
    #   - "success" [Boolean]
    #   - "raw_text" [String] if extraction succeeded
    #   - "message" [String] if extraction failed
    #
    def call
      ocr_data(@document)
    end

    private

    ##
    # Handles parsing the PDF and determining if OCR is needed.
    #
    # @param document [String, File, IO] The PDF document
    # @return [Hash]
    #
    def ocr_data(document)
      extracted_text = String.new
      is_scanned = false

      file = get_file_from(document)
      reader = if file.respond_to?(:path)
                PDF::Reader.new(file.path)
              else
                PDF::Reader.new(file)
              end

      reader.pages.each do |page|
        page_text = safe_page_text(page)
        extracted_text << " " << page_text

        if page_text.strip.empty? || mostly_junk?(page_text)
          is_scanned = true
          break
        end
      end

      if is_scanned || scanned_pdf?(extracted_text)
        scanned_pdf_ocr(file)
      else
        { "success" => true, "raw_text" => clean(extracted_text) }
      end
    rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError => e
      log_warning "PDF parsing failed: #{e.message}"
      scanned_pdf_ocr(file)
    end

    ##
    # Returns a File object from the given document
    #
    # @param document [String, File, IO]
    # @return [File]
    # @raise [ArgumentError] if the type is unsupported
    #
    def get_file_from(document)
      return document.tap(&:open) if document.respond_to?(:open)
      return document if document.is_a?(File)
      return document if document.respond_to?(:read)
      return File.open(document) if document.is_a?(String)

      raise ArgumentError, "Unsupported document type: #{document.class}"
    end

    ##
    # Safely extract text from a PDF page
    #
    # @param page [PDF::Reader::Page]
    # @return [String]
    #
    def safe_page_text(page)
      page.text.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    rescue
      ""
    end

    ##
    # Determine if a PDF is likely scanned
    #
    # @param text [String]
    # @return [Boolean]
    #
    def scanned_pdf?(text)
      return true if text.empty?
      junk_ratio = text.count("^A-Za-z0-9\s").to_f / text.size
      junk_ratio > 0.5 || text.size < 100
    end

    ##
    # Check if the page is mostly non-text content
    #
    # @param text [String]
    # @return [Boolean]
    #
    def mostly_junk?(text)
      return true if text.empty?
      text.scan(/[A-Za-z]/).count < (text.size * 0.2)
    end

    ##
    # Perform OCR on scanned PDFs
    #
    # @param file [File, String]
    # @return [Hash]
    #
    def scanned_pdf_ocr(file)
      images = []
      full_text = ""

      images = if file.respond_to?(:path)
                convert_pdf_to_images(file.path)
              else
                convert_pdf_to_images(file)
              end
      full_text += images.map { |img| extract_text(img) }.join(" ")

      unless full_text.strip.empty?
        { "success" => true, "raw_text" => clean(full_text) }
      else
        { "success" => false, "message" => "Unable to extract text using OCR" }
      end
    ensure
      cleanup(images)
    end

    ##
    # Convert PDF to PNG images
    #
    # @param pdf_path [String]
    # @return [Array<String>] List of image paths
    #
    def convert_pdf_to_images(pdf_path)
      output_prefix = File.join(Dir.tmpdir, "ocr_page_#{SecureRandom.hex(4)}")
      system("pdftoppm -png -r 300 #{Shellwords.escape(pdf_path)} #{Shellwords.escape(output_prefix)}")
      Dir["#{output_prefix}-*.png"]
    end

    ##
    # Extract text from an image using Tesseract
    #
    # @param image_path [String]
    # @return [String]
    #
    def extract_text(image_path)
      RTesseract.new(image_path, lang: "eng", processor: "mini_magick").to_s
    rescue => e
      log_warning "OCR failed on #{image_path}: #{e.message}"
      ""
    end

    ##
    # Cleanup temporary images
    #
    # @param images [Array<String>]
    #
    def cleanup(images)
      images&.each { |img| File.delete(img) if File.exist?(img) }
    end

    ##
    # Log warnings to Rails logger or stderr
    #
    # @param message [String]
    #
    def log_warning(message)
      if defined?(Rails)
        Rails.logger.warn(message)
      else
        warn(message)
      end
    end

    def clean(raw_text)
      return "" if raw_text.empty?

      raw_text
        .gsub(/\n+/, " ")
        .gsub(/\s+/, " ")
        .gsub(/-\s+/, "")
        .gsub(" . .", ".00")
        .encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
        .strip
    end
  end
end
