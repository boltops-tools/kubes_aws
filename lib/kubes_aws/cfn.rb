module KubesAws
  class Cfn < Kubes::CLI::Base
    include KubesAws::Services # for cfn client

    def initialize(options={})
      super
      # @stack_name needs to be an instance variable for KubesAws::Services::Concerns
      @stack_name = ["kubes", Kubes.app, Kubes.env, Kubes.extra].compact.join("-")
      @wait = @options[:wait].nil? ? true : @options[:wait]
    end

    def deploy
      sure?("Will deploy #{@stack_name.color(:green)} stack to create or update resources defined in #{sure_message_path}")
      @template = Builder.new(@options).template
      begin
        create_or_update
        url_info
        return unless @wait
        status.wait
        exit 2 unless status.success?
      rescue Aws::CloudFormation::Errors::ValidationError => e
        if e.message.include?("No updates") # No updates are to be performed.
          logger.info "#{e.message}".color(:yellow)
        elsif e.message.include?("At least one Resources member must be defined")
          logger.info "ERROR: ValidationError #{e.message}".color(:red)
          logger.info "Maybe the .kubes/aws files are empty or do not define any resources?"
        else
          logger.info "ERROR ValidationError: #{e.message}".color(:red)
          exit 1
        end
      end
    end

    def create_or_update
      template_body = YAML.dump(@template)
      action = stack_exists?(@stack_name) ? :update_stack : :create_stack
      human_action = action.to_s.split("_").map(&:capitalize).join(" ")
      # IE: Creating stack kubes-demo-dev
      logger.info "#{human_action} #{@stack_name}"
      cfn.send(action,
        stack_name: @stack_name,
        template_body: template_body,
        capabilities: ["CAPABILITY_IAM"]
      )
    end

    def show
      stack = find_stack(@stack_name)
      unless stack
        logger.info "Stack #{@stack_name.color(:green)} does not exist."
        exit 1
      end

      pp stack.to_h
    end

    def delete
      sure?("Will delete #{@stack_name.color(:green)} stack to delete resources defined in #{sure_message_path}")
      stack = find_stack(@stack_name)
      unless stack
        logger.info "Stack #{@stack_name.color(:green)} does not exist."
        exit 1
      end

      if stack.stack_status =~ /_IN_PROGRESS$/
        logger.info "Cannot delete stack #{@stack_name.color(:green)} in this state: #{stack.stack_status.color(:green)}"
        return
      end

      cfn.delete_stack(stack_name: @stack_name)
      logger.info "Deleting stack #{@stack_name.color(:green)}"

      return unless @wait
      status.wait
    end

    def url_info
      stack = cfn.describe_stacks(stack_name: @stack_name).stacks.first
      url = "https://console.aws.amazon.com/cloudformation/home?region=#{region}#/stacks"
      logger.info "Stack name #{@stack_name.color(:yellow)} status #{stack["stack_status"].color(:yellow)}"
      logger.info "Here's the CloudFormation url to check for more details #{url}"
    end

    # User confirmation shows the path to either
    #   .kubes/aws/APP
    # or
    #   .kubes/aws
    def sure_message_path
      if Dir.glob(".kubes/aws/#{Kubes.app}/*").any?
        ".kubes/aws/#{Kubes.app}"
      else
        ".kubes/aws"
      end
    end
  end
end
