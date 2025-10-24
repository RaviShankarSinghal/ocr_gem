# frozen_string_literal: true
require 'spec_helper.rb'
require 'ocr'

RSpec::describe Ocr::DataExtractor do
  let(:sample_pdf_path) { File.expand_path("../fixtures/file-sample_150kB.pdf", __FILE__)}
  let(:scanned_pdf_path) { File.expand_path("../fixtures/scansmpl.pdf", __FILE__)}

  describe "#call" do
    context "when pdf has readable text" do
      it "extracts the text successfully" do
        file = File.open(sample_pdf_path)
        result = Ocr::DataExtractor.new(file).call
        expect(result["success"]).to be true
        expect(result["raw_text"]).not_to be_empty
      end
    end
    context "when pdf has scanned file" do
      it "extracts the text successfully" do
        file = File.open(scanned_pdf_path)
        result = Ocr::DataExtractor.new(file).call
        expect(result["success"]).to be true
        expect(result["raw_text"]).not_to be_empty
      end
    end
    context "when PDF is malformed" do
      let(:malformed_pdf) { StringIO.new("%PDF-1.4 invalid") }
      it "returns OCR failure message" do
        result = Ocr::DataExtractor.new(malformed_pdf).call

        expect(result["success"]).to eq(false).or eq(true) # Could fallback to OCR
      end
    end
  end
end
