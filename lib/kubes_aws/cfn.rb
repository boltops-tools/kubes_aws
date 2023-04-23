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
      @template = build

      stack = find_stack(@stack_name)
      if stack && rollback_terminal?(stack)
        logger.info "Existing stack in terminal state: #{stack.stack_status}. Deleting stack before continuing."
        cfn.delete_stack(stack_name: @stack_name)
        status.wait
        status.reset
        stack = nil # at this point stack has been deleted
      end

      begin
        create_or_update
        url_info
        return unless @wait
        status.wait
        exit 2 unless status.success?
      rescue Aws::CloudFormation::Errors::ValidationError => e
        if e.message.include?("No updates") # No updates are to be performed.
          logger.info "#{e.message}"
        # elsif e.message.include?("At least one Resources member must be defined")
        #   logger.info "ERROR: ValidationError #{e.message}".color(:red)
        #   logger.info "Maybe the .kubes/aws files are empty or do not define any resources?"
        else
          logger.info "ERROR ValidationError: #{e.message}".color(:red)
          exit 1
        end
      end
    end

    def create_or_update
      template_body = YAML.dump(@template)
      action = exist? ? :update_stack : :create_stack
      human_action = action.to_s.split("_").map(&:capitalize).join(" ")
      # IE: Creating stack kubes-demo-dev
      logger.info "#{human_action} #{@stack_name} for resources in #{sure_message_path}"
      cfn.send(action,
        stack_name: @stack_name,
        template_body: template_body,
        capabilities: ["CAPABILITY_IAM"]
      )
    end

    def build
      Builder.new(@options).template
    end

    def show
      stack = find_stack(@stack_name)
      unless stack
        logger.info "Stack #{@stack_name.color(:green)} does not exist."
        exit 1
      end
      stack
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

    def managed_iam_role
      unless exist?
        logger.debug "WARN: KubesAws.managed_iam_role: stack does not exist."
        logger.debug "Maybe you need to run kubes aws deploy?"
        return
      end
      stack = show
      output = stack.outputs.find { |o| o.output_key == "IamRoleArn" }
      output.output_value if output
    end

    def managed_security_group
      unless exist?
        logger.debug "WARN: KubesAws.managed_security_group: stack does not exist."
        logger.debug "Maybe you need to run kubes aws deploy?"
        return
      end
      stack = show
      output = stack.outputs.find { |o| o.output_key == "SecurityGroupId" }
      output.output_value if output
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

    # Used in KubesAws.managed_iam_role_arn
    def exist?
      stack_exists?(@stack_name)
    end

    # Typically happens when IAM permissions are not setup correctly
    def rollback_terminal?(stack)
      %w[DELETE_FAILED ROLLBACK_COMPLETE ROLLBACK_FAILED].include?(stack.stack_status)
    end
  end
end
