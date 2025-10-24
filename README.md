# OCR

A lightweight Ruby gem for extracting text from PDFs, including scanned PDFs using OCR.

This gem supports:

- PDFs with readable text
- Scanned PDFs using Tesseract OCR
- File objects, file paths, StringIO, and Rails/ActiveStorage uploads
- Fully Rails-independent

---

## 🚀 Features

- Detect if PDF is scanned or text-based
- Extract text from normal PDFs using `PDF::Reader`
- Extract text from scanned PDFs using `RTesseract` and `MiniMagick`
- Automatic cleanup of temporary images

---

## 💻 Installation

Add this line to your application's Gemfile:

```ruby
gem 'ocr', git: 'https://github.com/your_username/ocr.git'
```

Or install directly:
```ruby
gem install ocr
```

## Dependencies
- PDF::Reader

- RTesseract

- MiniMagick

- Tesseract OCR (system-level executable)

- pdftoppm from Poppler utils (for converting PDF pages to images)

## ⚙️ Usage
```ruby
require 'ocr'
require 'stringio'

# From a File object
file = File.open("path/to/document.pdf")
result = Ocr::DataExtractor.new(file).call
puts result["raw_text"] if result["success"]

# From a file path string
result = Ocr::DataExtractor.new("path/to/document.pdf").call

# From a StringIO object (in-memory PDF)
pdf_data = StringIO.new(File.read("path/to/document.pdf"))
result = Ocr::DataExtractor.new(pdf_data).call
```

## Example Result
```ruby
{
  "success" => true,
  "raw_text" => "Extracted text content from PDF ..."
}
```
- If OCR fails for a scanned PDF:
```ruby
{
  "success" => false,
  "message" => "Unable to extract text using OCR"
}
```
## 🔧 Notes
1. Ensure Tesseract OCR is installed on your system:
```
# Ubuntu/Debian
sudo apt install tesseract-ocr

# MacOS (with Homebrew)
brew install tesseract
```
2. Ensure pdftoppm is installed (for PDF-to-image conversion):
```
# Ubuntu/Debian
sudo apt install poppler-utils

# MacOS (with Homebrew)
brew install poppler
```
3. This gem does not require Rails, but it will work with Rails ActiveStorage objects that respond to .open.

## 🧪 Running Tests
```
bundle install
bundle exec rspec
```

- PDFs with selectable text

- Scanned PDFs

- Malformed PDFs (fallback to OCR)

## 📝 Contributing

- Fork the repository

- Create your feature branch (git checkout -b your-feature)

- Commit your changes (git commit -am 'Add new feature')

- Push to the branch (git push origin your-feature)

- Open a Pull Request

## 🧑‍💼 Author
```
Ravi Shankar Singhal
Senior Backend Developer — Ruby on Rails
📧 ravi.singhal2308@gmail.com

🌐 https://github.com/RaviShankarSinghal
```

## 📝 License

MIT License © RaviShankarSinghal


---

This version includes:

- Version and build badges (replace with your repo info)  
- Clear installation instructions  
- Usage examples for File, path, and StringIO  
- System dependencies  
- Test instructions  
- Contributing guidelines  
- The gem is available as open source under the terms of the MIT License.
---
