require "faraday"

class ApiProxyController < ApplicationController
  def forward_request
    service_url = determine_service_url(params[:path])
    return render json: { error: "Service not found" }, status: :not_found unless service_url

    begin
      response = forward_to_service(service_url, request.path)
      render_response(response)
    rescue Faraday::Error => e
      Rails.logger.error "Proxy error: #{e.message}"
      render json: { error: "Service unavailable" }, status: :service_unavailable
    rescue StandardError => e
      Rails.logger.error "Unexpected error: #{e.message}"
      render json: { error: "Internal server error" }, status: :internal_server_error
    end
  end

  private

  def determine_service_url(path)
    return Rails.application.config.user_service_url if path.starts_with?("users")
    return Rails.application.config.user_service_url if path.starts_with?("collections")

    nil
  end

  def forward_to_service(service_url, full_path)
    conn = Faraday.new(url: service_url) do |faraday|
      faraday.adapter Faraday.default_adapter
    end

    conn.send(
      request.method.downcase.to_sym,
      full_path
    ) do |req|
      # Handle request body
      if request.body.respond_to?(:read)
        body_content = request.body.read
        request.body.rewind if request.body.respond_to?(:rewind)
        req.body = body_content unless body_content.empty?
      end

      # Add filtered headers
      filtered_headers.each do |key, value|
        req.headers[key] = value if value.is_a?(String)
      end

      # Add query parameters
      req.params.merge!(request.query_parameters) if request.query_parameters.any?
    end
  end

  def filtered_headers
    headers = {}
    request.headers.each do |key, value|
      next if key.start_with?("HTTP_HOST", "HTTP_VERSION", "SERVER_NAME", "SERVER_PORT")
      next if key.start_with?("action_controller", "action_dispatch")
      next unless value.is_a?(String)

      # Convert Rails header format to standard HTTP headers
      if key.start_with?("HTTP_")
        header_name = key[5..-1].split("_").map(&:capitalize).join("-")
        headers[header_name] = value
      elsif %w[CONTENT_TYPE CONTENT_LENGTH].include?(key)
        header_name = key.split("_").map(&:capitalize).join("-")
        headers[header_name] = value
      end
    end
    headers
  end

  def render_response(response)
    content_type = response.headers["content-type"]

    if content_type&.include?("application/json")
      render json: response.body, status: response.status
    else
      render plain: response.body, status: response.status
    end
  end
end
