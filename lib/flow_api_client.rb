# Stub client for the Flow API (Modern Treasury's internal payments engine).
# In production, this would make authenticated HTTP calls to the Flow service.
module FlowApiClient
  def self.patch(path)
    # Demo stub — always returns success
    Rails.logger.info("[FlowApiClient] PATCH #{path}")
    { success: true }
  end
end
