# frozen_string_literal: true

class AuthenticationController < ApplicationController
  skip_before_action :authenticate_request
  def login
    begin
      response = forward_login_to_user_service

      if response.status == 200
        user_data = JSON.parse(response.body)

        # Generate both access and refresh tokens
        access_token_data = generate_access_token(user_data["id"])
        refresh_token_data = generate_refresh_token(user_data["id"])

        render json: {
          access_token: access_token_data[:token],
          refresh_token: refresh_token_data[:token],
          access_token_expires_at: access_token_data[:expires_at],
          refresh_token_expires_at: refresh_token_data[:expires_at],
          token_type: "Bearer",
          user: user_data
        }, status: :ok
      else
        error_data = JSON.parse(response.body) rescue { error: "Invalid credentials" }
        render json: error_data, status: response.status
      end
    rescue Faraday::Error => e
      Rails.logger.error "Authentication service error: #{e.message}"
      render json: { error: "Authentication service unavailable" }, status: :service_unavailable
    rescue StandardError => e
      Rails.logger.error "Authentication error: #{e.message}"
      render json: { error: "Authentication failed" }, status: :internal_server_error
    end
  end

  def refresh
    begin
      header = request.headers["Authorization"]
      refresh_token = header.split(" ").last if header

      return render json: { error: "Refresh token required" }, status: :bad_request unless refresh_token

      # Decode and validate refresh token
      decoded_token = JWT.decode(refresh_token, Rails.application.credentials.secret_key_base, true, algorithm: "HS256")
      payload = decoded_token[0]

      return render json: { error: "Invalid token type" }, status: :bad_request unless payload["token_type"] == "refresh"

      user_id = payload["user_id"]

      # Generate a new access token
      access_token_data = generate_access_token(user_id)

      render json: {
        access_token: access_token_data[:token],
        access_token_expires_at: access_token_data[:expires_at],
        token_type: "Bearer"
      }, status: :ok

    rescue JWT::ExpiredSignature
      render json: { error: "Refresh token expired" }, status: :unauthorized
    rescue JWT::DecodeError
      render json: { error: "Invalid refresh token" }, status: :unauthorized
    rescue StandardError => e
      Rails.logger.error "Token refresh error: #{e.message}"
      render json: { error: "Token refresh failed" }, status: :internal_server_error
    end
  end

  private

  def forward_login_to_user_service
    conn = Faraday.new(url: Rails.application.config.user_service_url) do |faraday|
      faraday.adapter Faraday.default_adapter
    end

    conn.post("/api/v1/auth/login") do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = request.raw_post
    end
  end

  def generate_access_token(user_id)
    expires_at = 1.hour.from_now
    payload = {
      user_id: user_id,
      token_type: "access",
      exp: expires_at.to_i
    }
    token = JWT.encode(payload, Rails.application.credentials.secret_key_base, "HS256")

    {
      token: token,
      expires_at: expires_at.iso8601
    }
  end

  def generate_refresh_token(user_id)
    expires_at = 7.days.from_now
    payload = {
      user_id: user_id,
      token_type: "refresh",
      exp: expires_at.to_i
    }
    token = JWT.encode(payload, Rails.application.credentials.secret_key_base, "HS256")

    {
      token: token,
      expires_at: expires_at.iso8601
    }
  end
end
