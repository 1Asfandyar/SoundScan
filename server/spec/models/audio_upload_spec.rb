# frozen_string_literal: true

RSpec.describe AudioUpload, type: :model do
  let(:valid_attributes) do
    {
      filename: "sample.mp3",
      file_hash: "abc123",
      duration: 12.5,
      bitrate: 128,
      sample_rate: 44_100,
      quality_score: 8,
      storage_path: "/tmp/sample.mp3"
    }
  end

  it "is valid with valid attributes" do
    expect(described_class.new(valid_attributes)).to be_valid
  end

  it "requires audio metadata fields" do
    upload = described_class.new(
      valid_attributes.merge(
        filename: nil,
        file_hash: nil,
        duration: nil,
        bitrate: nil,
        sample_rate: nil,
        quality_score: nil,
        storage_path: nil
      )
    )

    expect(upload).not_to be_valid
    expect(upload.errors).to include(
      :filename,
      :file_hash,
      :duration,
      :bitrate,
      :sample_rate,
      :quality_score,
      :storage_path
    )
  end

  it "requires a unique file hash" do
    described_class.create!(valid_attributes)

    duplicate = described_class.new(valid_attributes)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:file_hash]).to include("has already been processed")
  end

  it "requires duration to be greater than zero" do
    upload = described_class.new(valid_attributes.merge(duration: 0))

    expect(upload).not_to be_valid
    expect(upload.errors[:duration]).to include("must be greater than 0")
  end

  it "requires quality score to be between 1 and 10" do
    upload = described_class.new(valid_attributes.merge(quality_score: 11))

    expect(upload).not_to be_valid
    expect(upload.errors[:quality_score]).to include("must be a grade between 1 and 10")
  end
end
