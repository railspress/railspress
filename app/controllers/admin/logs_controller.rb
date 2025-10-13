class Admin::LogsController < Admin::BaseController
  # GET /admin/logs
  def index
    @log_files = available_log_files
    @current_log = params[:file] || 'development'
  end
  
  # GET /admin/logs/stream
  def stream
    log_file = params[:file] || 'development'
    log_path = Rails.root.join('log', "#{log_file}.log")
    
    unless File.exist?(log_path)
      render plain: "Log file not found: #{log_file}.log", status: :not_found
      return
    end
    
    # Set headers for Server-Sent Events
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Cache-Control'] = 'no-cache'
    response.headers['X-Accel-Buffering'] = 'no'
    
    # Stream the log file
    lines = params[:lines]&.to_i || 100
    
    self.response_body = Enumerator.new do |yielder|
      begin
        # Send initial tail of the log
        initial_lines = tail_file(log_path, lines)
        yielder << "data: #{initial_lines.to_json}\n\n"
        
        # Watch for new lines
        File.open(log_path, 'r') do |file|
          file.seek(0, IO::SEEK_END)
          
          loop do
            line = file.gets
            
            if line
              yielder << "data: #{line.to_json}\n\n"
            else
              sleep 0.5
              # Check if file was rotated
              file.seek(0, IO::SEEK_CUR)
            end
          end
        end
      rescue IOError
        # Client disconnected
      end
    end
  end
  
  # GET /admin/logs/download
  def download
    log_file = params[:file] || 'development'
    log_path = Rails.root.join('log', "#{log_file}.log")
    
    unless File.exist?(log_path)
      redirect_to admin_logs_path, alert: "Log file not found: #{log_file}.log"
      return
    end
    
    send_file log_path,
              filename: "#{log_file}-#{Date.today}.log",
              type: 'text/plain',
              disposition: 'attachment'
  end
  
  # DELETE /admin/logs/clear
  def clear
    log_file = params[:file] || 'development'
    log_path = Rails.root.join('log', "#{log_file}.log")
    
    if File.exist?(log_path)
      File.truncate(log_path, 0)
      redirect_to admin_logs_path(file: log_file), notice: "Log file cleared: #{log_file}.log"
    else
      redirect_to admin_logs_path, alert: "Log file not found: #{log_file}.log"
    end
  end
  
  # GET /admin/logs/search
  def search
    log_file = params[:file] || 'development'
    query = params[:q]
    log_path = Rails.root.join('log', "#{log_file}.log")
    
    unless File.exist?(log_path)
      render json: { error: 'Log file not found' }, status: :not_found
      return
    end
    
    results = []
    line_number = 0
    
    File.foreach(log_path) do |line|
      line_number += 1
      if line.downcase.include?(query.downcase)
        results << { line_number: line_number, content: line.strip }
        break if results.size >= 100  # Limit results
      end
    end
    
    render json: { results: results, query: query, count: results.size }
  end
  
  private
  
  def available_log_files
    log_dir = Rails.root.join('log')
    Dir.glob(log_dir.join('*.log')).map do |file|
      basename = File.basename(file, '.log')
      {
        name: basename,
        path: file,
        size: File.size(file),
        modified: File.mtime(file)
      }
    end.sort_by { |f| f[:modified] }.reverse
  end
  
  def tail_file(file_path, lines = 100)
    content = []
    
    File.open(file_path, 'r') do |file|
      file.seek(0, IO::SEEK_END)
      position = file.pos
      line_count = 0
      
      # Go backwards through the file
      while position > 0 && line_count < lines
        position -= 1
        file.seek(position)
        char = file.read(1)
        
        if char == "\n"
          line_count += 1
          break if line_count >= lines
        end
      end
      
      content = file.read.split("\n")
    end
    
    content.last(lines)
  end
end





