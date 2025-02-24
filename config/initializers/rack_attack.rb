class Rack::Attack
  throttle("google_drive_credentials", limit: 10, period: 1.minute) do |req|
    if req.path == "/google_drive/credentials" && req.get?
      req.ip
    end
  end
end
