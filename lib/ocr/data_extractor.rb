require "ocr_extractor/version"
require "pdf/reader"
require "rtesseract"
require "securerandom"
require "shellwords"

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

      document.file.open do |file|
        reader = PDF::Reader.new(file.path)

        reader.pages.each do |page|
          page_text = safe_page_text(page)
          extracted_text << " " << page_text

          if page_text.blank? || mostly_junk?(page_text)
            is_scanned = true
            break
          end
        end
      end

      if is_scanned || scanned_pdf?(extracted_text)
        scanned_pdf_ocr(document)
      else
        { "success" => true, "raw_text" => extracted_text.strip }
      end
    rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError => e
      Rails.logger.warn "PDF parsing failed: #{e.message}" if defined?(Rails)
      scanned_pdf_ocr(document)
    end

    def safe_page_text(page)
      page.text.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    rescue
      ""
    end

    def scanned_pdf?(text)
      return true if text.blank?
      junk_ratio = text.count("^A-Za-z0-9\s").to_f / text.size
      junk_ratio > 0.5 || text.size < 100
    end

    def mostly_junk?(text)
      return true if text.blank?
      text.scan(/[A-Za-z]/).count < (text.size * 0.2)
    end

    def scanned_pdf_ocr(document)
      images = []
      full_text = nil

      document.file.open do |file|
        images = convert_pdf_to_images(file.path)
        full_text = images.map { |img| extract_text(img) }.join("\n")
      end

      if full_text.present?
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
      RTesseract.new(image_path, lang: "eng").to_s
    rescue => e
      Rails.logger.warn "OCR failed on #{image_path}: #{e.message}" if defined?(Rails)
      ""
    end

    def cleanup(images)
      images&.each { |img| File.delete(img) if File.exist?(img) }
    end
  end
end
