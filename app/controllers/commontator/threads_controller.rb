module Commontator
  class ThreadsController < Commontator::ApplicationController
    skip_before_filter :ensure_user, :only => :show
    before_filter :set_thread

    # GET /threads/1
    def show
      commontator_thread_show(@thread.commontable)
      @show_all = params[:show_all] && @thread.can_be_edited_by?(@user)

      respond_to do |format|
        format.html { redirect_to main_app.polymorphic_path(@thread.commontable) }
        format.js
      end
    end
    
    # PUT /threads/1/close
    def close
      security_transgression_unless @thread.can_be_edited_by?(@user)

      unless @thread.close(@user)
        @thread.errors.add(:base,
          t('commontator.thread.errors.already_closed'))
      end

      @show_all = true

      respond_to do |format|
        format.html { redirect_to @thread }
        format.js { render :show }
      end
    end
    
    # PUT /threads/1/reopen
    def reopen
      security_transgression_unless @thread.can_be_edited_by?(@user)

      unless @thread.reopen
        @thread.errors.add(:base, t('commontator.thread.errors.not_closed'))
      end

      @show_all = true

      respond_to do |format|
        format.html { redirect_to @thread }
        format.js { render :show }
      end
    end

    # GET /threads/1/mentions.json
    def mentions
      security_transgression_unless @thread.can_be_read_by?(@user) && Commontator.mentions_enabled
      query = params[:q].to_s

      if query.size < 3
        render json: { errors: ['Query string is too short (minimum 3 characters)'] },
               status: :unprocessable_entity
      else
        render json: serialized_mentions(query)
      end
    end

    protected

    def serialized_mentions(query)
      { mentions: Commontator.commontator_mentions(@user, query).map do |user|
        { id: user.id, name: Commontator.commontator_name(user), type: 'user' }
      end }
    end
  end
end
