module EventCalendar
  module CalendarHelper
    class Calendar
      def initialize options, block=nil
        setup options

        outer_calendar_container do
          table_header_and_links

          body_container_for_day_names_and_rows do
            add_day_names
            # container for all the calendar rows
            calendar_rows_container do
              add_weeks
            end
          end
        end
      end

      def to_s
        @html
      end

      def << html
        @html << html
      end

      private

      attr_reader :row_num, :first_day_of_week, :last_day_of_week,
        :last_day_of_cal, :top, :first, :last, :options

      # check if we should display without a background color
      def no_event_bg? event
        options[:use_all_day] && !event.all_day && event.days == 0
      end

      def setup options
        # default month name for the given number
        if options[:show_header]
          options[:month_name_text] ||= I18n.translate(:'date.month_names')[options[:month]]
        end

        # the first and last days of this calendar month
        if options[:dates].is_a?(Range)
          @first = options[:dates].begin
          @last  = options[:dates].end
        else
          @first = Date.civil(options[:year], options[:month],  1)
          @last  = Date.civil(options[:year], options[:month], -1)
        end

        @options = options
        @html = ""
      end


      def outer_calendar_container
        self << %(<div class="ec-calendar")
        self << %(style="width: #{options[:width]}px;") if options[:width]
        self << %(>)
        yield

        self << %(</div>)
      end

      def table_header_and_links
        if options[:show_header]
          self << %(<table class="ec-calendar-header" cellpadding="0" cellspacing="0">)
          self << %(<thead><tr>)
          if options[:previous_month_text] or options[:next_month_text]
            self << %(<th colspan="2" class="ec-month-nav ec-previous-month">#{options[:previous_month_text]}</th>)
            colspan = 3
          else
            colspan = 7
          end

          self << %(<th colspan="#{colspan}" class="ec-month-name">#{options[:month_name_text]}</th>)

          if options[:next_month_text]
            self << %(<th colspan="2" class="ec-month-nav ec-next-month">#{options[:next_month_text]}</th>)
          end
          self << %(</tr></thead></table>)
        end
      end

      def height
        height = options[:day_names_height]
        row_heights.each do |row_height|
          height += row_height
        end
        height
      end


      def body_container_for_day_names_and_rows
        self << %(<div class="ec-body" style="height: #{height}px;">)
        yield
        self << %(</div>)
      end

      def add_day_names
        self << %(<table class="ec-day-names" style="height: #{options[:day_names_height]}px;" cellpadding="0" cellspacing="0">)
        self << %(<tbody><tr>)
        day_names.each do |day_name|
          self << %(<th class="ec-day-name" title="#{day_name}">#{day_name}</th>)
        end
        self << %(</tr></tbody></table>)
      end

      def day_names
        day_names = []
        if options[:abbrev]
          day_names.concat I18n.translate(:'date.abbr_day_names')
        else
          day_names.concat I18n.translate(:'date.day_names')
        end

        options[:first_day_of_week].times do
          day_names.push(day_names.shift)
        end
        day_names
      end

      def calendar_rows_container
        self << %(<div class="ec-rows" style="top: #{options[:day_names_height]}px; )
        self << %(height: #{height - options[:day_names_height]}px;">)
        yield

        self << %(</div>)
      end

      def add_weeks
        # initialize loop variables
        @first_day_of_week = beginning_of_week(first, options[:first_day_of_week])
        @last_day_of_week = end_of_week(first, options[:first_day_of_week])
        @last_day_of_cal = end_of_week(last, options[:first_day_of_week])
        @row_num = 0
        @top = 0

        # go through a week at a time, until we reach the end of the month
        while(last_day_of_week <= last_day_of_cal)
          add_week_row

          # increment the calendar row we are on, and the week
          @row_num += 1
          @first_day_of_week += 7
          @last_day_of_week += 7
        end
      end

      def add_week_row
        week_row_container do
          @top += row_heights[row_num]

          week_background_table

          calendar_row do
            day_numbers_row

            # event rows for this day
            # for each event strip, create a new table row
            options[:event_strips].each do |strip|
              event_row_for_this_day strip
            end

          end
        end
      end

      def week_row_container
        self << %(<div class="ec-row" style="top: #{top}px; height: #{row_heights[row_num]}px;">)
        yield
        self << %(</div>)
      end

      def week_background_table
        self << %(<table class="ec-row-bg" cellpadding="0" cellspacing="0">)
        self << %(<tbody><tr>)
        first_day_of_week.upto(last_day_of_week) do |day|
          today_class = (day == Date.today) ? "ec-today-bg" : ""
          other_month_class = (day < first) || (day > last) ? 'ec-other-month-bg' : ''
          self << %(<td class="ec-day-bg #{today_class} #{other_month_class}">&nbsp;</td>)
        end
        self << %(</tr></tbody></table>)
      end

      def calendar_row
        self << %(<table class="ec-row-table" cellpadding="0" cellspacing="0">)
        self << %(<tbody>)
        yield
        self << %(</tbody></table>)
      end

      def day_numbers_row
        self << %(<tr>)
        first_day_of_week.upto(last_day_of_week) do |day|
          self << %(<td class="ec-day-header )
          self << %(ec-today-header ) if options[:show_today] and (day == Date.today)
          self << %(ec-other-month-header ) if (day < first) || (day > last)
          self << %(ec-weekend-day-header) if weekend?(day)
          self << %(" style="height: #{options[:day_nums_height]}px;">)
          if options[:link_to_day_action]
            self << day_link(day.day, day, options[:link_to_day_action])
          else
            self << %(#{day.day})
          end
          self << %(</td>)
        end
        self << %(</tr>)
      end


      def event_row_for_this_day strip
        self << %(<tr>)
        # go through through the strip, for the entries that correspond to the days of this week
        strip[row_num*7, 7].each_with_index do |event, index|
          day = first_day_of_week + index

          if event
            new_cell_span event, day
          else
            empty_cell_and_container
          end
        end
        self << %(</tr>)
      end

      def new_cell_span event, day
        # get the dates of this event that fit into this week
        dates = event.clip_range(first_day_of_week, last_day_of_week)
        # if the event (after it has been clipped) starts on this date,
        # then create a new cell that spans the number of days
        if starts_this_day? event, day
          cell_container event do
            add_arrows event

            if no_event_bg? event
              self << %(<div class="ec-bullet" style="background-color: #{event.color};"></div>)
              # make sure anchor text is the event color
              # here b/c CSS 'inherit' color doesn't work in all browsers
              self << %(<style type="text/css">.ec-#{css_for(event)}-#{event.id} a { color: #{event.color}; }</style>)
            end

            if @block
              # add the additional html that was passed as a block to this helper
              self << @block.call({:event => event, :day => day.to_date, :options => options})
            else
              # default content in case nothing is passed in
              default_cell_content event
            end

          end
        end
      end

      def cell_container event
        col_span = (last_day_in_week_for(event)-first_day_in_week_for(event)).to_i + 1

        self << %(<td class="ec-event-cell" colspan="#{col_span}" )
        self << %(style="padding-top: #{options[:event_margin]}px;">)
        self << %(<div id="ec-#{css_for(event)}-#{event.id}" class="ec-#{css_for(event)}-#{event.id} )

        cell_attributes event
        self << %(>)

        yield

        self << %(</div></td>)
      end

      def cell_attributes event
        if no_event_bg? event
          self << %(ec-event-no-bg" )
          self << %(style="color: #{event.color}; )
        else
          self << %(ec-event-bg" )
          self << %(style="background-color: #{event.color}; )
        end

        self << %(padding-top: #{options[:event_padding_top]}px; )
        self << %(height: #{options[:event_height] - options[:event_padding_top]}px;" )
        if options[:use_javascript]
          # custom attributes needed for javascript event highlighting
          self << %(data-event-id="#{event.id}" data-event-class="#{css_for(event)}" data-color="#{event.color}" )
        end
      end

      def add_arrows event
        self << %(<div class="ec-left-arrow"></div>)  if clipped? :at_beginning, event
        self << %(<div class="ec-right-arrow"></div>) if clipped? :at_end, event
      end

      def clipped? where, event
        if where == :at_beginning
          event.start_at.to_date < first_day_in_week_for(event)
        elsif where == :at_end
          event.end_at.  to_date > last_day_in_week_for(event)
        end
      end

      def default_cell_content event
        self << %(<a href="/#{css_for(event).pluralize}/#{event.id}" title="#{(event.name)}">#{(event.name)}</a>)
      end

      def css_for event
        event.class.name.tableize.singularize
      end

      def starts_this_day? event, day
        first_day_in_week_for(event) == day.to_date
      end

      def first_day_in_week_for event
        dates_within_this_week_for(event)[0]
      end

      def last_day_in_week_for event
        dates_within_this_week_for(event)[1]
      end

      def dates_within_this_week_for event
        event.clip_range(first_day_of_week, last_day_of_week)
      end

      def empty_cell_and_container
        self << %(<td class="ec-event-cell ec-no-event-cell" )
        self << %(style="padding-top: #{options[:event_margin]}px;">)
        self << %(<div class="ec-event" )
        self << %(style="padding-top: #{options[:event_padding_top]}px; )
        self << %(height: #{options[:event_height] - options[:event_padding_top]}px;" )
        self << %(>)
        self << %(&nbsp;</div></td>)

      end
      # calculate the height of each row
      # by default, it will be the height option minus the day names height,
      # divided by the total number of calendar rows
      # this gets tricky, however, if there are too many event rows to fit into the row's height
      # then we need to add additional height
      def row_heights
        # number of rows is the number of days in the event strips divided by 7
        num_cal_rows = options[:event_strips].first.size / 7
        # the row will be at least this big
        min_height = (options[:height] - options[:day_names_height]) / num_cal_rows
        row_heights = []
        num_event_rows = 0
        # for every day in the event strip...
        1.upto(options[:event_strips].first.size+1) do |index|
          num_events = 0
          # get the largest event strip that has an event on this day
          options[:event_strips].each_with_index do |strip, strip_num|
            num_events = strip_num + 1 unless strip[index-1].blank?
          end
          # get the most event rows for this week
          num_event_rows = [num_event_rows, num_events].max
          # if we reached the end of the week, calculate this row's height
          if index % 7 == 0
            total_event_height = options[:event_height] + options[:event_margin]
            calc_row_height = (num_event_rows * total_event_height) + options[:day_nums_height] + options[:event_margin]
            row_height = [min_height, calc_row_height].max
            row_heights << row_height
            num_event_rows = 0
          end
        end
        row_heights
      end

      #
      # helper methods for working with a calendar week
      #

      def days_between(first, second)
        if first > second
          second + (7 - first)
        else
          second - first
        end
      end

      def beginning_of_week(date, start = 0)
        days_to_beg = days_between(start, date.wday)
        date - days_to_beg
      end

      def end_of_week(date, start = 0)
        beg = beginning_of_week(date, start)
        beg + 6
      end

      def weekend?(date)
        [0, 6].include?(date.wday)
      end

    end
  end
end
