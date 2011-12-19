module EventCalendar
  module CalendarHelper

    # Returns an HTML calendar which can show multiple, overlapping events across calendar days and rows.
    # Customize using CSS, the below options, and by passing in a code block.
    #
    # The following are optional, available for customizing the default behaviour:
    # :month => Time.now.month # The month to show the calendar for. Defaults to current month.
    # :year => Time.now.year # The year to show the calendar for. Defaults to current year.
    # :dates => (start_date .. end_date) # Show specific range of days. Defaults to :year, :month.
    # :abbrev => true # Abbreviate day names. Reads from the abbr_day_names key in the localization file.
    # :first_day_of_week => 0 # Renders calendar starting on Sunday. Use 1 for Monday, and so on.
    # :show_today => true # Highlights today on the calendar using CSS class.
    # :show_header => true # Show the calendar's header. (month name, next, & previous links)
    # :month_name_text => nil # Displayed center in header row.
    #     Defaults to current month name from Date::MONTHNAMES hash.
    # :previous_month_text => nil # Displayed left of the month name if set
    # :next_month_text => nil # Displayed right of the month name if set
    # :event_strips => [] # An array of arrays, encapsulating the event rows on the calendar
    #
    # :width => nil # Width of the calendar, if none is set then it will stretch the container's width
    # :height => 500 # Approx minimum total height of the calendar (excluding the header).
    #     Height could get added if a day has too many event's to fit.
    # :day_names_height => 18 # Height of the day names table (included in the above 'height' option)
    # :day_nums_height => 18 # Height of the day numbers tables (included in the 'height' option)
    # :event_height => 18 # Height of an individual event row
    # :event_margin => 1 # Spacing of the event rows
    # :event_padding_top => 1 # Padding on the top of the event rows (increase to move text down)
    #
    # :use_all_day => false # If set to true, will check for an 'all_day' boolean field when displaying an event.
    #     If it is an all day event, or the event is multiple days, then it will display as usual.
    #     Otherwise it will display without a background color bar.
    # :use_javascript => true # Outputs HTML with inline javascript so events spanning multiple days will be highlighted.
    #     If this option is false, cleaner HTML will be output, but events spanning multiple days will
    #     not be highlighted correctly on hover, so it is only really useful if you know your calendar
    #     will only have single-day events. Defaults to true.
    # :link_to_day_action => false # If controller action is passed,
    #     the day number will be a link. Override the day_link method for greater customization.
    #
    # For more customization, you can pass a code block to this method
    # The varibles you have to work with in this block are passed in an agruments hash:
    # :event => The event to be displayed.
    # :day => The day the event is displayed on. Usually the first day of the event, or the first day of the week,
    #   if the event spans a calendar row.
    # :options => All the calendar options in use. (User defined and defaults merged.)
    #
    # For example usage, see README.
    #
    #
    def defaults
       { :year => (Time.zone || Time).now.year,
        :month => (Time.zone || Time).now.month,
        :abbrev => true,
        :first_day_of_week => 0,
        :show_today => true,
        :show_header => true,
        :month_name_text => (Time.zone || Time).now.strftime("%B %Y"),
        :previous_month_text => nil,
        :next_month_text => nil,
        :event_strips => [],

        # it would be nice to have these in the CSS file
        # but they are needed to perform height calculations
        :width => nil,
        :height => 500,
        :day_names_height => 18,
        :day_nums_height => 18,
        :event_height => 18,
        :event_margin => 1,
        :event_padding_top => 2,

        :use_all_day => false,
        :use_javascript => true,
        :link_to_day_action => false
      }

    end

    def calendar(options = {}, &block)
      block ||= Proc.new {|d| nil}

      options = defaults.merge options
      Calendar.new(options, block).to_s
    end


    # override this in your own helper for greater control
    def day_link(text, date, day_action)
      link_to(text, params.merge(:action => day_action, :year => date.year, :month => date.month, :day => date.day), :class => 'ec-day-link')
    end

    # default html for displaying an event's time
    # to customize: override, or do something similar, in your helper
    # for instance, you may want to add localization
    def display_event_time(event, day)
      time = event.start_at
      if !event.all_day and time.to_date == day
        # try to make it display as short as possible
        format = (time.min == 0) ? "%l" : "%l:%M"
        t = time.strftime(format)
        am_pm = time.strftime("%p") == "PM" ? "p" : ""
        t += am_pm
        %(<span class="ec-event-time">#{t}</span>)
      else
        ""
      end
    end
  end
end
