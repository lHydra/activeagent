# frozen_string_literal: true

module ActiveAgent
  module Callbacks
    extend ActiveSupport::Concern

    included do
      include ActiveSupport::Callbacks
      define_callbacks :generation, skip_after_callbacks_if_terminated: true
      define_callbacks :stream, skip_after_callbacks_if_terminated: true
    end

    module ClassMethods
      [:before, :after, :around].each do |callback|
        define_method "#{callback}_generation" do |*names, &blk|
          _insert_callbacks(names, blk) do |name, options|
            set_callback(:generation, callback, name, options)
          end
        end
      end

      # # Defines a callback that will get called right before the
      # # prompt is sent to the generation provider method.
      # def before_generation(*filters, &blk)
      #   set_callback(:generation, :before, *filters, &blk)
      # end
      #
      # # Defines a callback that will get called right after the
      # # prompt's generation method is finished.
      # def after_generation(*filters, &blk)
      #   set_callback(:generation, :after, *filters, &blk)
      # end
      #
      # # Defines a callback that will get called around the prompt's generation method.
      # def around_generation(*filters, &blk)
      #   set_callback(:generation, :around, *filters, &blk)
      # end

      # Defines a callback for handling streaming responses during generation
      def on_stream(*filters, &blk)
        set_callback(:stream, :before, *filters, &blk)
      end

      private

      def _insert_callbacks(callbacks, block = nil)
        options = callbacks.extract_options!
        callbacks.push(block) if block
        options[:filters] = callbacks
        _normalize_callback_options(options)
        options.delete(:filters)
        callbacks.each do |callback|
          yield callback, options
        end
      end

      def _normalize_callback_options(options)
        _normalize_callback_option(options, :only, :if)
        _normalize_callback_option(options, :except, :unless)
      end

      def _normalize_callback_option(options, from, to) # :nodoc:
        if from_value = options.delete(from)
          # filters = options[:filters]
          from_value = -> { Array(from_value).map(&:to_s).to_set.include?(action_name) }
          options[to] = Array(options[to]).unshift(from_value)
        end
      end
    end

    # Helper method to run stream callbacks
    def run_stream_callbacks(message, delta = nil, stop = false)
      run_callbacks(:stream) do
        yield(message, delta, stop) if block_given?
      end
    end
  end
end
