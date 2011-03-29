/*
	Component.Calendar v1.3
	Copyryght 2007 Imperavi
	http://lab.imperavi.ru
*/

if(typeof(Component) == 'undefined')
  var Component = {};
Component.Calendar = Class.create();
Object.extend(Component.Calendar.prototype,{
	daysInMonth: [31,28,31,30,31,30,31,31,30,31,30,31],
//	formats: ['d.m.y', 'd/m/y', 'd-m-y', 'y.m.d', 'y/m/d', 'y-m-d', 'm.d.y', 'm/d/y', 'm-d-y'],
	formats: ['y-m-d','y-m-d','y-m-d','y-m-d','y-m-d','y-m-d','y-m-d','y-m-d','y-m-d','y-m-d'],
	languageDay: $H({
	'fr': [ 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim' ],
	'en': [ 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun' ],
	'sp': [ 'Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'S&#224;b', 'Dom' ],
	'it': [ 'Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom' ],
	'de': [ 'Mon', 'Die', 'Mit', 'Don', 'Fre', 'Sam', 'Son' ],
	'pt': [ 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'S&#225;', 'Dom' ],
	'ru': [ 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс' ]
	}),
	languageMonth: $H({
	'fr': [ 'Janvier', 'F&#233;vrier', 'Mars', 'Avril', 'Mai', 'Juin',
		'Juillet', 'Aout', 'Septembre', 'Octobre', 'Novembre', 'D&#233;cembre' ],
	'en': [ 'January', 'February', 'March', 'April', 'May',
		'June', 'July', 'August', 'September', 'October', 'November', 'December' ],
	'sp': [ 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
		'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre' ],
	'it': [ 'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
		'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre' ],
	'de': [ 'Januar', 'Februar', 'M&#228;rz', 'April', 'Mai', 'Juni',
		'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember' ],
	'pt': [ 'Janeiro', 'Fevereiro', 'Mar&#231;o', 'Abril', 'Maio', 'Junho',
		'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro' ],
	'ru': [ 'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
		'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь' ]
	}),
	loaded: false,
	todayDate: new Date(),
	dateRegexp: /^(.*?)(\/|\.|\-)(.*?)(?:\/|\.|\-)(.*?)$/,
	initialize: function(element, options)
	{
		this.element = $(element);
		this.element_id = element;

        this.options = Object.extend({
            format: false,
			autoFormat: true,
			location: false,
			fullMonth: false,
			split: false,
			revert: false,
			lang: 'ru',
			click: false,
           	date: null,
			day: 1,
		    month: 0,
		    year: 2007,
			splitter: '.',
			embed: false,
			js:false,
			forbiddenfrom:false,
			forbiddento:false
        }, options || {});

       	if (this.options.click) Event.observe($(this.options.click), 'click', this.load.bindAsEventListener(this), false);
		else Event.observe(this.element, 'click', this.load.bindAsEventListener(this), false);

		if (this.options.embed) this.load();
    },
	load: function()
	{
		this.iframe_id = this.element_id + '_calendar_iframe';
		this.calendar_id = this.element_id + '_calendar';
		this.calendar_head_id = this.element_id + '_calendar_head';
		this.table_box_id = this.element_id + '_calendar_box';
		this.table_id = this.element_id + '_calendar_table';

		this.getCurrentDate();
		if (!this.loaded) this.build();
		else
		{
    	    this.drawCalendar();
			this.show();
		}

		if (!this.options.embed) Event.observe(document, "mousedown", this.bodyClick_handler=this.bodyClick.bindAsEventListener(this),false);
	},
	build: function()
	{
		this.loaded = true;

 		this.calendar_div = Builder.node('div',{id: this.calendar_id, className: 'component_calendar', style: 'display:none;'},
		[
			Builder.node('table',{className:'component_calendar_header'},
			[
		        Builder.node('tbody', [
					Builder.node('tr', [
    					Builder.node('td', {id: this.element_id + '_calendar_prev_year'}, ' << '),
						Builder.node('td', {id: this.element_id + '_calendar_prev_month'}, ' < '),
						Builder.node('td', {id: this.calendar_head_id, className: 'component_calendar_head_name'}),
						Builder.node('td', {id: this.element_id + '_calendar_next_month'}, ' > '),
						Builder.node('td', {id: this.element_id + '_calendar_next_year'}, ' >> ')
					])
				])
			]),
			Builder.node('div',{id: this.table_box_id, className:'component_calendar_box'})
		]);


        if (Prototype.Browser.IE && !this.options.embed)
		{
			this.iframe = Builder.node('iframe',{id: this.iframe_id, style: 'position: absolute; display:none;'});
			document.body.appendChild(this.iframe);
		}

		if (!this.options.embed) document.body.appendChild(this.calendar_div);
		else $(this.element).appendChild(this.calendar_div);

		Event.observe($(this.element_id + '_calendar_prev_month'), 'click', this.prevMonth.bindAsEventListener(this), false);
		Event.observe($(this.element_id + '_calendar_next_month'), 'click', this.nextMonth.bindAsEventListener(this), false);

		Event.observe($(this.element_id + '_calendar_next_year'), 'click', this.nextYear.bindAsEventListener(this), false);
		Event.observe($(this.element_id + '_calendar_prev_year'), 'click', this.prevYear.bindAsEventListener(this), false);

		this.drawCalendar();
		if (!this.options.embed) this.setPostion();
		this.show();

	},
	setPostion: function()
	{
    	if (this.options.click) var dimensions = $(this.options.click).getDimensions();
		else var dimensions = this.element.getDimensions();

		this._leftOffset = 0;
		this._topOffset	= dimensions.height;

		if (this.options.click) var a_lt = Position.cumulativeOffset($(this.options.click));
		else var a_lt = Position.positionedOffset($(this.element));

		var left = Number(a_lt[0]+this._leftOffset);
		var top = Number(a_lt[1]+this._topOffset);


		$(this.calendar_id).setStyle({
			'position': 'absolute',
		    'left'	: left + 'px',
		    'top'	: top + 'px'
		   });

		this.correctPosition(this.calendar_id, left, top, 180);

		if (Prototype.Browser.IE && !this.options.embed)
		{
			var dim_cal = $(this.calendar_id).getDimensions();

			$(this.iframe_id).setStyle({
			    'left': $(this.calendar_id).style.left,
			    'top': $(this.calendar_id).style.top,
				'height': dim_cal.height,
				'width': dim_cal.width,
				'border': '0px'
			   });


		   $(this.iframe_id).show();
		}
	},
	correctPosition: function(element, left, top, popup_width)
	{
		var windowWidth = document.body.offsetWidth;
		if ((left + popup_width) > windowWidth) left = left - popup_width;

		$(element).setStyle({
		top: top + 'px',
		left: left + 'px'
		});

	},
	drawCalendar: function ()
	{
		this.setLocaleHeader();
		if ($(this.table_id) != null) $(this.table_id).remove();
		var table = Builder.node('table',{id: this.table_id, className:'component_calendar_table'});

		table.appendChild(this.buildCalendar());
		$(this.table_box_id).appendChild(table);
	},
	buildCalendar: function()
	{
		/*
		 	This method is the improved version of DatePicker widget using Prototype and Scriptaculous by Mathieu Jondet
		*/
		var _self = this;
		var tbody = Builder.node('tbody');

		/* generate day headers */
		var trDay = Builder.node('tr');

		this.languageDay.get(this.options.lang).each(
			function (item)
			{
				var td = Builder.node('td', {className: 'wday'},item);
				trDay.appendChild( td );
			});
		tbody.appendChild(trDay);

		/* generate the content of days */

		/* build-up days matrix */
		var a_d	= [
			 [ 0, 0, 0, 0, 0, 0, 0 ]
			,[ 0, 0, 0, 0, 0, 0, 0 ]
			,[ 0, 0, 0, 0, 0, 0, 0 ]
			,[ 0, 0, 0, 0, 0, 0, 0 ]
			,[ 0, 0, 0, 0, 0, 0, 0 ]
			,[ 0, 0, 0, 0, 0, 0, 0 ]
		];

		/* set date at beginning of month to display */
		var d = new Date(this.options.year, this.options.month, 1, 12);

		/* start the day list on monday */
		var startIndex	= ( !d.getDay() ) ? 6 : d.getDay() - 1;
		var nbDaysInMonth = this.getMonthDays(this.options.year, this.options.month);

		var daysIndex = 1;

		for (var j = startIndex; j < 7; j++ )
		{
			a_d[0][j] = {
				d : daysIndex,
			 	m : this.options.month,
				y : this.options.year,
				c : (this.options.forbiddenfrom<=(this.options.year+'-'+this._leftpad_zero(this.options.month+1,2)+'-'+this._leftpad_zero(daysIndex,2))) ? 'forbidden' : 
				    ((this.options.forbiddento>=(this.options.year+'-'+this._leftpad_zero(this.options.month+1,2)+'-'+this._leftpad_zero(daysIndex + 1,2))) ? 'forbidden' : '')
			};
			daysIndex++;
		}

		var a_prevMY = this._prevMonthYear();
		var nbDaysInMonthPrev = this.getMonthDays(a_prevMY[1], a_prevMY[0]);

		for (var j = 0; j < startIndex; j++ )
		{
			a_d[0][j] = {
				d : Number(nbDaysInMonthPrev - startIndex + j + 1),
				m : Number(a_prevMY[0]),
				y : a_prevMY[1],
				c : (this.options.forbiddenfrom<=(a_prevMY[1]+'-'+this._leftpad_zero(Number(a_prevMY[0])+1,2)+'-'+this._leftpad_zero(Number(nbDaysInMonthPrev - startIndex + j + 1),2))) ? 'forbidden' : 
					((this.options.forbiddento>=(a_prevMY[1]+'-'+this._leftpad_zero(Number(a_prevMY[0])+1,2)+'-'+this._leftpad_zero(Number(nbDaysInMonthPrev - startIndex + j + 1),2))) ? 'forbidden' : 'outbound')
			};
		}

		var switchNextMonth	= false;
		var currentMonth = this.options.month;
		var currentYear = this.options.year;
		for (var i = 1; i < 6; i++ )
		{
//			if(this.options.forbiddenfrom<(currentYear+'-'+this._leftpad_zero(currentMonth,2)+'-'+this._leftpad_zero(daysIndex,2)))
//			 alert(this.options.forbiddenfrom+'<'+(currentYear+'-'+this._leftpad_zero(currentMonth,2)+'-'+this._leftpad_zero(daysIndex,2)));
			for ( var j = 0; j < 7; j++ )
			{
				a_d[i][j] = {
					d : daysIndex,
					m : currentMonth,
					y : currentYear,
					c : (this.options.forbiddenfrom<=(currentYear+'-'+this._leftpad_zero(currentMonth+1,2)+'-'+this._leftpad_zero(daysIndex,2))) ? 'forbidden' : (
						(this.options.forbiddento>=(currentYear+'-'+this._leftpad_zero(currentMonth+1,2)+'-'+this._leftpad_zero(daysIndex + 1,2))) ? 'forbidden' : (
							( switchNextMonth ) ? 'outbound' : (
								((daysIndex == this.todayDate.getDate()) &&
								(this.options.month  == this.todayDate.getMonth()) &&
								(this.options.year == this.todayDate.getFullYear())) ? 'today' : null)
						)
						)
					};
					daysIndex++;

					/* if at the end of the month : reset counter */
					if ( daysIndex > nbDaysInMonth )
					{
						daysIndex	= 1;
						switchNextMonth = true;
						if ( this.options.month + 1 > 11 )
						{
							currentMonth = 0;
							currentYear += 1;
						}
						else
						{
							currentMonth += 1;
						}
					}
			}
		}

		/* generate days for current date */
		for ( var i = 0; i < 6; i++ )
		{
			var tr	= Builder.node('tr');
			for ( var j = 0; j < 7; j++ )
			{
				var h_ij = a_d[i][j];

				/*
					id is : datepicker-day-mon-year or depending on language other way
					don't forget to add 1 on month for proper formmatting
				*/
				if (this.options.lang == 'en' )
				{
					var id = $A([this._leftpad_zero((h_ij["m"] +1), 2), this._leftpad_zero(h_ij["d"], 2), h_ij["y"] ]).join('-');
				}
				else
				{
					var id = $A([this._leftpad_zero(h_ij["d"], 2), this._leftpad_zero((h_ij["m"] + 1), 2), h_ij["y"] ]).join('-');
				}


				var td_class = '';
				if (h_ij["c"]) td_class = h_ij["c"];
				if (h_ij["d"] == this.options.day && h_ij["m"] == this.options.month && h_ij["c"]!='forbidden') td_class = 'now';

				var td = Builder.node('td', {id: id, className: td_class}, h_ij["d"]);

				/* on onclick : rebuild date value from id of current cell */
			if(td_class!='forbidden')
			{
				td.onclick	= function ()
				{
					var str = $(this).readAttribute('id');

				    var	match = str.split('-');

					if (_self.options.lang == 'en')
					{
						var day = match[1];
						var month = match[0];
					}
					else
					{
						var day = match[0];
						var month = match[1];
					}

	  				if (_self.options.fullMonth) month = _self.getMonthLocale(month);
					var year = match[2];

					var c_date = _self.options.format.replace('d', day);
					c_date = c_date.replace('m', month);
					c_date = c_date.replace('y', year);

   	 				if (_self.options.split)
					{
						if (_self.options.split == 'all') _self.setSplitAll(day, month, year);
						else if (_self.options.split == 'mix') _self.setSplitMix(day, month, year);
					}
		 			else if (_self.options.location) _self.toLocation(c_date);
		 			else if (_self.options.js) _self.toJs(c_date);
		 			else _self.setValue(c_date);

				};
			};
				td.onmouseover = function () { $(this).addClassName('over'); };
				td.onmouseout = function () { $(this).removeClassName('over'); };

				tr.appendChild(td);
			}
			tbody.appendChild(tr);
		}
		return tbody;
	},
	getCurrentDate: function ()
	{
		if (this.options.click == this.element_id || this.options.embed)
		{
			if (this.options.embed)
			{
				var day	= this.options.day;
				var month = this.options.month + 1;
				var year = this.options.year;

                if (this.options.lang == 'en' ) this.options.date = month + this.options.splitter + day + this.options.splitter + year;
				else this.options.date = day + this.options.splitter + month + this.options.splitter + year;

			}
			else this.options.date = false;
		}
		else
		{
       		if (this.options.split)
			{
           		var year = this.element.value;
  				var day = $(this.element_id + '_d').value;
  				var month = $(this.element_id + '_m').value;

				if (this.options.lang == 'en' ) this.options.date = month + this.options.splitter + day + this.options.splitter + year;
				else this.options.date = day + this.options.splitter + month + this.options.splitter + year;
			}
			else this.options.date = $F(this.element);
		}



	   	var regex = this.dateRegexp;

		if (!regex.test(this.options.date))
		{
			var now	= new Date();
			var day	= this._leftpad_zero(now.getDate(), 2);
			var mon	= this._leftpad_zero(now.getMonth() + 1, 2);

			if (this.options.revert)
			{
            	this.options.date = now.getFullYear() + this.options.splitter + mon+ this.options.splitter  + day;
			}
			else
			{
				if (this.options.lang == 'en' ) this.options.date = mon+ this.options.splitter  + day + this.options.splitter  +now.getFullYear();
				else this.options.date = day+ this.options.splitter  + mon + this.options.splitter + now.getFullYear();
			}
		}

		var a_date_regexp = this.options.date.match(regex);
		if (a_date_regexp == undefined) return true;

		if (a_date_regexp[1].length == 4) this.options.revert = true;

		/* fetch date separator as specified in option or via value */
		this.options.splitter  = String(a_date_regexp[2]);

		if (this.options.autoFormat && !this.options.format) this.options.format = this.getFormat();

		/* check language */
       	if (this.options.revert)
		{
   			this.options.day = Number(a_date_regexp[4]);
   			this.options.month = Number(a_date_regexp[3]) - 1;
   			this.options.year = Number(a_date_regexp[1]);
		}
		else
		{
			if (this.options.lang == 'en' )
			{
				this.options.month = Number(a_date_regexp[1]) - 1;
				this.options.day = Number(a_date_regexp[3]);

			}
			else
			{
				this.options.day = Number(a_date_regexp[1]);
				this.options.month = Number(a_date_regexp[3]) - 1;
			}
			this.options.year = Number(a_date_regexp[4]);
		}
	},
	getFormat: function()
	{
		var format;
		if (this.options.revert)
		{
			if (this.options.splitter == '.') format = this.formats[3];
			else if (this.options.splitter == '/') format = this.formats[4];
			else format = this.formats[5];
		}
		else if (this.options.lang == 'en')
		{
			if (this.options.splitter == '.') format = this.formats[6];
			else if (this.options.splitter == '/') format = this.formats[7];
			else format = this.formats[8];
		}
		else
		{
			if (this.options.splitter == '.') format = this.formats[0];
			else if (this.options.splitter == '/') format = this.formats[1];
			else format = this.formats[2];
		}

		return format;
	},
	getMonthLocale: function (month)
	{
		return this.languageMonth.get(this.options.lang)[month];
	},
	getLocaleClose: function()
	{
		return this.languageClose.get(this.options.lang);
	},
	setLocaleHeader: function ()
	{
		$(this.calendar_head_id).update(this.getMonthLocale(this.options.month)+'&nbsp;'+this.options.year);
	},
    setToday: function()
	{

	},
	setSplitMix: function(day, month, year)
	{
		this.element.value = year;

		$(this.element_id + '_d').selectedIndex = parseInt(day-1);
		$(this.element_id + '_m').selectedIndex = parseInt(month-1);

		this.close();
	},
	setSplitAll: function(day, month, year)
	{
		this.element.value = year;
		$(this.element_id + '_d').value = day;
		$(this.element_id + '_m').value = month;
		this.close();
	},
	setValue: function(date)
	{
		this.element.value = date;
		this.close();
	},
	toLocation: function(date)
	{
		top.location.href = this.options.location + date;
		this.close();
	},
	toJs: function(date)
	{
		eval(this.options.js);
		this.element.value = date;
		this.close();
	},
	_leftpad_zero: function(str, padToLength)
	{
		var result	= '';
		for ( var i = 0; i < (padToLength - String(str).length); i++ )
			result += '0';
		return result + str;
	},
	getMonthDays: function (year, month)
	{
		if (((0 == (year%4)) && ((0 != (year%100)) || (0 == (year%400)))) && (month == 1)) return 29;
		return this.daysInMonth[month];
	},
	bodyClick: function(e)
	{
		var _self = this;
		var close = true;

		$(Event.element(e)).ancestors().each(
			function (s)
			{
				if (s.id == _self.calendar_id) close = false;
			}
		);

	   if (close) this.close();
	},
	show: function()
	{
		if (!this.options.embed) this.setPostion();

		if (Prototype.Browser.IE && !this.options.embed) $(this.iframe_id).show();
		$(this.calendar_id).show();
	},
	close: function()
	{
		if (Prototype.Browser.IE && !this.options.embed) $(this.iframe_id).hide();
		Event.stopObserving(document, "mousedown", this.bodyClick_handler);
		$(this.calendar_id).hide();
   	},
	nextMonth: function ()
	{
		var a_next = this._nextMonthYear();
		this.options.month	= a_next[0];
		this.options.year 	= a_next[1];
		this.drawCalendar();
	},
	prevMonth: function ()
	{
		var a_prev = this._prevMonthYear();
		this.options.month = a_prev[0];
		this.options.year = a_prev[1];
		this.drawCalendar();
	},
	nextYear: function ()
	{
    	this.options.year 	= this.options.year+1;
		this.drawCalendar();
	},
	prevYear: function ()
	{
		this.options.year 	= this.options.year-1;
		this.drawCalendar();
	},
	_prevMonthYear: function ()
	{
		var c_mon = this.options.month;
		var c_year = this.options.year;
		if ( c_mon - 1 < 0 )
		{
			c_mon = 11;
			c_year	-= 1;
		}
		else
		{
			c_mon -= 1;
		}
		return [ c_mon, c_year ];
	},
	_nextMonthYear: function ()
	{
		var c_mon = this.options.month;
		var c_year = this.options.year;
		if ( c_mon + 1 > 11 )
		{
			c_mon = 0;
			c_year += 1;
		}
		else
		{
			c_mon += 1;
		}
		return [ c_mon, c_year ];
	}
});
if(typeof(Object.Event) != 'undefined')
	Object.Event.extend(Component.Calendar);

