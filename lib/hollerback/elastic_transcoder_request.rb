module Hollerback
  class ElasticTranscoderRequest
    PIPELINE_ID  = "1369278513259-ejysz1"
    PRESET_BEST  = "1369345552712-nuthg1"
    PRESET_MED   = "1369345608098-9ggpbp"
    PRESET_WORST = "1369351292621-wiht25"

    def initialize(video)
      @video = video
      @file = video.filename
      @transcoder = AWS::ElasticTranscoder::Client.new
    end

    def run
      resp = create_job

      if job_id = resp[:job][:id]
        StreamJob.create(
          :master_playlist => playlist,
          :video_id => @video.id,
          :job_id => job_id
        )
      end
    end

    def playlist
      s3_key.split("/")[1]
    end

    def s3_key
      @file.split(".").first.gsub("_testSegmentedVids/", "")
    end

    private

    def create_job
      @transcoder.create_job(
        pipeline_id: PIPELINE_ID,
        input: {
          key: @file,
          frame_rate: 'auto',
          resolution: 'auto',
          aspect_ratio: 'auto',
          interlaced: 'auto',
          container: 'auto'
        },
        outputs: [
          {
            key: "#{s3_key}/1",
            preset_id: PRESET_BEST,
            thumbnail_pattern: "",
            rotate: "auto",
            segment_duration: "3"
          },
          {
            key: "#{s3_key}/2",
            preset_id: PRESET_MED,
            thumbnail_pattern: "",
            rotate: "auto",
            segment_duration: "3"
          },
          {
            key: "#{s3_key}/3",
            preset_id: PRESET_WORST,
            thumbnail_pattern: "",
            rotate: "auto",
            segment_duration: "3"
          },
        ],
        playlists: [{
          name: "#{playlist}",
          format: "HLSv3",
          output_keys: ["#{s3_key}/1", "#{s3_key}/2", "#{s3_key}/3"]
        }]
      )
    end
  end
end
