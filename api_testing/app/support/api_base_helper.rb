module ApiBaseHelper
  private_class_method def self.execute(url, request, request_body = nil)
    http = Net::HTTP.new(url.host, url.port)
    http.open_timeout = 120
    http.use_ssl = (url.scheme == 'https')
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    # request.body = request_body.to_json unless request_body.nil?
    puts ''
    puts "Request Header: #{request.to_hash}"
    puts "Request URL: #{url}"
    puts "Request body: #{request_body}"

    retries = 1
    begin
      $response = http.request(request)
    rescue Exception => e
      p e.message
      retry if (retries += 1) < 5
      raise e.message if retries == 5
    end

    # $response.body = JSON.parse($response.read_body) unless $response.read_body.nil? || $response.read_body.empty?
    # $response

    puts "Response code: #{$response.code}"
    puts "Response body: #{$response.body}"
    puts ''

    begin
      $response.body = JSON.parse($response.read_body)
      $response
    rescue StandardError
      p 'response is not json'
      $response
    end
  end

  def post(endpoint, request_body = nil)
    url = url(endpoint)
    request = Net::HTTP::Post.new(url)
    send(:execute, url, request, request_body)
  end

  def get(endpoint, request_body = nil)
    url = url(endpoint)
    request = Net::HTTP::Get.new(url)
    send(:execute, url, request, request_body)
  end

  def put(endpoint, request_body = nil)
    url = url(endpoint)
    request = Net::HTTP::Put.new(url)
    send(:execute, url, request, request_body)
  end

  def patch(endpoint, request_body = nil)
    url = URI($base_url_api.to_s + endpoint)
    request = Net::HTTP::Patch.new(url)
    request.body = request_body.to_json unless request_body.nil?
    send(:execute, url, request, request_body)
  end

  def delete(endpoint, request_body = nil)
    url = url(endpoint)
    request = Net::HTTP::Delete.new(url)
    request.body = request_body.to_json unless request_body.nil?
    send(:execute, url, request, request_body)
  end

  def post_form_data(endpoint, request_body = nil)
    url = URI($base_url_api.to_s + endpoint)
    request = Net::HTTP::Post.new(url)
    request.set_form_data(request_body)
    send(:execute, url, request, request_body)
  end
end
