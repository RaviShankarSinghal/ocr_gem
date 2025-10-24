require "mini_magick"
require "pdf/reader"
require "rtesseract"
require "securerandom"
require "shellwords"
require "tmpdir"

module Ocr
  class DataExtractor
    def initialize(document)
      @document = document
    end

    def call
      ocr_data(@document)
    end

    private

    def ocr_data(document)
      extracted_text = ""
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
        { "success" => true, "raw_text" => extracted_text.strip }
      end
    rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError => e
      log_warning "PDF parsing failed: #{e.message}"
      scanned_pdf_ocr(file)
    end

    def get_file_from(document)
      return document.tap(&:open) if document.respond_to?(:open)
      return document if document.is_a?(File)
      return document if document.respond_to?(:read)
      return File.open(document) if document.is_a?(String)

      raise ArgumentError, "Unsupported document type: #{document.class}"
    end

    def safe_page_text(page)
      page.text.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    rescue
      ""
    end

    def scanned_pdf?(text)
      return true if text.empty?
      junk_ratio = text.count("^A-Za-z0-9\s").to_f / text.size
      junk_ratio > 0.5 || text.size < 100
    end

    def mostly_junk?(text)
      return true if text.empty?
      text.scan(/[A-Za-z]/).count < (text.size * 0.2)
    end

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
        { "success" => true, "raw_text" => full_text.strip }
      else
        { "success" => false, "message" => "Unable to extract text using OCR" }
      end
    ensure
      cleanup(images)
    end

    def convert_pdf_to_images(pdf_path)
      output_prefix = File.join(Dir.tmpdir, "ocr_page_#{SecureRandom.hex(4)}")
      system("pdftoppm -png -r 300 #{Shellwords.escape(pdf_path)} #{Shellwords.escape(output_prefix)}")
      Dir["#{output_prefix}-*.png"]
    end

    def extract_text(image_path)
      RTesseract.new(image_path, lang: "eng", processor: "mini_magick").to_s
    rescue => e
      log_warning "OCR failed on #{image_path}: #{e.message}"
      ""
    end

    def cleanup(images)
      images&.each { |img| File.delete(img) if File.exist?(img) }
    end

    def log_warning(message)
      if defined?(Rails)
        Rails.logger.warn(message)
      else
        warn(message)
      end
    end
  end
end
