# frozen_string_literal: true

RSpec.describe "Audio uploads", type: :request do
  let(:audio) do
    tempfile = Tempfile.new([ "sample", ".mp3" ])
    tempfile.write("fake upload")
    tempfile.rewind

    ActionDispatch::Http::UploadedFile.new(
      tempfile: tempfile,
      filename: "sample.mp3",
      type: "audio/mpeg"
    )
  end

  it "returns the analyzer result" do
    result = {
      id: 1,
      duplicate: false,
      duration: "03:24",
      is_outlier: false,
      outliers: [],
      quality_score: 10,
      metadata: {
        filename: "sample.mp3",
        bitrate_kbps: 128,
        sample_rate_hz: 44100
      }
    }

    allow(Audio::Analyzer).to receive(:call).and_return(result)

    post "/api/upload", params: { audio: audio }

    expect(response).to have_http_status(:created)
    expect(JSON.parse(response.body)["success"]).to eq(true)
    expect(JSON.parse(response.body)["result"]).to eq(JSON.parse(result.to_json))
  end
end
