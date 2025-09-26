class ApplicationController < ActionController::API
  before_action :authenticate_request

  def authenticate_request
    header = request.headers["Authorization"]
    token = header.split(" ").last if header

    return render json: { error: "Access token required" }, status: :unauthorized unless token

    begin
      decoded_token = JWT.decode(token, Rails.application.credentials.secret_key_base, true, algorithm: "HS256")
      payload = decoded_token[0]

      # For API requests, only accept access tokens
      if payload["token_type"] != "access"
        return render json: { error: "Invalid token type" }, status: :unauthorized
      end

      @current_user_id = payload["user_id"]

      # Add the user ID to the request headers for downstream services
      request.headers["X-User-ID"] = @current_user_id.to_s
    rescue JWT::ExpiredSignature
      render json: { error: "Access token expired" }, status: :unauthorized
    rescue JWT::DecodeError
      render json: { error: "Invalid access token" }, status: :unauthorized
    end
  end
end
