`(function(a){a.fn.extend({outerHTML:function(b){if(!this.length)return null;else if(b===undefined){var c=this.length?this[0]:this,d;if(c.outerHTML)d=c.outerHTML;else d=a(document.createElement("div")).append(a(c).clone()).html();if(typeof d==="string")d=a.trim(d);return d}else if(a.isFunction(b)){this.each(function(c){var d=a(this);d.outerHTML(b.call(this,c,d.outerHTML()))})}else{var e=a(this),f=[],g=a(b),h;for(var i=0;i<e.length;i++){h=g.clone(true);e.eq(i).replaceWith(h);for(var j=0;j<h.length;j++)f.push(h[j])}return f.length?a(f):null}}})})(jQuery);`

String::slugify = () ->
	@trim().replace(/[\s,']+/g, '-').toLowerCase()

String::unSelectorize = () ->
	@replace('#', '')

Mathem = {}

class SectionStep
	# Markup template for a step
	@template = ['<li class="step clearfix" id="{{slug}}">',
				 '<div class="index">Step {{{id}}}.</div>',
				 '<div class="title">{{{text}}}</div>',
				 '<pre class="result">{{{result}}}</pre>',
         '{{{note_node}}}',
				 '</li>'].join('')

	constructor: (@id, @text, @result, @note, @plain) ->
		@slug = @id
		@plain = if @plain then 'plain' else 'math'

	setSection: (@section) ->
		@slug = @section.slug + '-' + @slug

	render: () ->
		template = Hogan.compile(SectionStep.template)
		@markup = template.render
			id: @id,
			slug: @slug,
			text: @text,
			result: @result.replace(/( {1})/g, '&nbsp;'),
			plain: @plain,
			note_node: if @note? then "<div class='note alert alert-info'><strong>NOTE:</strong> #{@note}</div>" else null
		@markup

	selector: () ->
		'#' + @slug

class Section
	@template = ['<section class="tab-pane section" id="{{slug}}">',
							   '<div class="page-header"><h1>{{title}}</h1></div>',
							   '<p class="lead">{{{description}}}<br />'
							   '<strong>Example:</strong> <span class="example math">{{{example}}}</span>',
							   '</p>',
							   '<hr>',
							   '<ol class="steps unstyled">',
							   '</ol></section>'].join('')

	constructor: (@id, @title, @description, @example, @stepsArray) ->
		@slug  = @title.slugify()
		@steps = []
		@template = Section.template

	initialize: () ->
		@addSteps(@stepsArray)
		@render()
		@

	setCategory: (@category) ->
		@slug = @category.slug + '-' + @slug
		@render()

	addStep: (step) ->
		if step.note? then step.note = step.note else step.note = null
		stepObj = new SectionStep(@steps.length+1, step.text, step.result, step.note, step.plain)
		stepObj.setSection(@)
		@steps.push(stepObj)

	addSteps: (steps) ->
		for step in steps
			@addStep(step)

	getSteps: () ->
		@steps

	render: () ->
		template = Hogan.compile(Section.template)
		@markup = template.render
			slug:        @slug
			title:       @title
			description: @description
			example:     @example
		@markup

	selector: () ->
		'#' + @slug


class Category
	constructor: (@id, @name) ->
		@slug     = @name.slugify()
		@sections = []

	addSection: (section) ->
		sectionObj = new Section(@sections.length+1, section.title, section.description, section.example, section.steps)
		sectionObj.setCategory(@)
		@sections.push(sectionObj.initialize())

	getSections: () ->
		@sections

	getSection: (name) ->
		for section in @sections
			if section.match(name)
				found = section
		found

	match: (search) ->
		found = null
		if @slug is search or @name is search or @id is search or @selector() is search
			found = @
		else
			found = null
		found

	selector: () ->
		'#' + @slug + '-content'

# Main data structure
categories = [
	'Standard',
	'Turbo Boost',
	'Divisiblity',
	'Perfect Squares',
	'Casting Out Nines',
	'Casting Out Elevens'
]

Mathem.categories = []
Mathem.categories.push(new Category(++index, name)) for name, index in categories

# All sections and their contents
sectionsData = {
	'standard': [
		title: 'Multiply as high as 19x19',
		description: 'Quickly multiply any two two-digit numbers up to 19 x 19.',
		example: '17 x 12 = 204',
		steps: [
			text: "Add the one's place digit form the smaller number to the larger number.",
			result: "17 + 2 = 19"
		,
			text: "Add a zero to the end.",
			result: "\"19\" + \"0\" = 190",
			plain: true
		,
			text: "Multiply the one's place digit of the two numbers.",
			result: "7 x 2 = 14"
		,
			text: "Add the results of steps 2 and 3 for the answer.",
			result: "190 + 14 = 204"
		]
	,
		title: 'Square a number ending in 5',
		description: 'Square any two-digit number ending in five.',
		example: '75 ^ 2 = 5625',
		steps: [
      text: "Multiply the first digit by itself <strong>plus one</strong>.",
      result: "7 x 8 = 56"
    ,
      text: "Place the number <strong>25</strong> on the end of the result.",
      result: '"56" + "25" = 5625'
    ]
  ,
    title: "Square any two digit number",
    description: "Square any two digit number.",
    example: '43 ^ 2 = 1849',
    steps: [
      text: 'Square each digit and place the answers side by side.'
      result: ['      4 ^ 2 = 16',
        			 '      3 ^ 2 = 9',
        			 '"16" + "09" = 16<u>09</u>'].join("\n")
      note: 'If a square is a single digit number, prepend it with 0.'
    ,
      text: 'Multiple the digits of the number being squared.'
      result: '4 x 3 = 12'
    ,
      text: 'Double the answer in step 2 and add a zero to the end.'
      result: ['    12 x 2 = 24',
      			   '"24" + "0" = 240'].join("\n")
    ,
      text: 'Add the results of step 1 and step 3.'
      result: '1609 + 240 = 1849'
    ]
  ,
  	title: 'Doubling and halving',
  	description: 'Multiply two numbers where one of them is an even number. This lesson works best when the even number is a power of two.',
  	example: '32 x 21 = 672',
  	steps: [
  		text: 'Halve the even number and double the other number',
  		result: ['21 x 2 = 42 &crarr;',
  						 '32 / 2 = 16'].join("\n")
 		,
 			text: 'Repeat until the answer is reached.',
 			result: [' 84 x 8 &crarr;',
 							 '168 x 4 &crarr;',
 							 '336 x 2 = 672'].join("\n")
  	]
  ,
  	title: 'Multiply any number by 4',
  	description: 'Quickly multiply any number by four.',
  	example: '72 x 4 = 288',
  	steps: [
  		text: 'Double the number being multiplied.',
  		result: '72 x 4 = 144'
  	,
  		text: 'Double it again.',
  		result: '144 x 2 = 288'
  	]
  ,
  	title: 'Multiply any number by 5',
  	description: 'Easily multiply any number by five.',
  	example: '27 x 5',
  	steps: [
  		text: 'Divide the number being multiplied by 2.',
  		result: '27 / 2 = 13.5'
  	,
  		text: 'Multiply Step 1 by 10.',
  		result: '13.5 x 10 = 135'
  	]
  ,
  	title: 'Multiply any number by 9',
  	description: 'Easily multiply any number by nine.',
  	example: '52 x 9 = 468',
  	steps: [
  		text: 'Multiply the number by 10.',
  		result: '52 x 10 = 520',
  		note: 'Just add a zero to multiply by ten.'
  	,
  		text: 'Subtract the number from the result in Step 1.',
  		result: '520 - 52 = 468'
  	]
  ,
  	title: 'Multiply any number by 25',
  	description: 'Easily multiply any number by twenty-four.',
  	example: '44 x 24 = 1100',
  	steps: [
  		text: 'Multiply the number by 100',
  		result: '44 x 100 = 4400'
  	,
  		text: 'Divide by 4',
  		result: '4400 / 4 = 1100'
  	]
  ,
  	title: 'Multiply any number by 99',
  	description: 'Multiply any number by ninety-nine.',
  	example: '440 x 99 = 43560',
  	steps: [
  		text: 'Multiply the number by 100',
  		result: '440 x 100'
  	,
  		text: 'Subtract the number from the result in Step 1.',
  		result: '44000 - 440 = 43560'
  	]
  ,
  	title: 'Squares from 41 to 59',
  	description: 'Quickly square numbers between fourty-one and fifty-nine.',
  	example: '47 ^ 2 = 2209',
  	steps: [
  		text: 'Subtract 25 from the number',
  		result: '47 - 25 = 22'
  	,
  		text: 'Square the difference between the number and 50',
  		result: ['50 - 47 = 3', '3 ^ 2 = <u>09</u>'].join("\n"),
  		note: 'If square is less than 10, prepend with 0.'
  	,
  		text: 'Put the answers from step 1 and step 2 together.',
  		result: '"22" + "09" = 2209'
  	]
  ,
  	title: 'Round number multiplication',
  	description: 'Multiply two numbers when a round number sits halfway between them.',
  	example: '73 x 67 = 4891',
  	steps: [
  		text: 'Identify the round number sitting equally between the two numbers.',
  		result: '67->68->69-> 70 <-71<-72<-73'
  	,
  		text: 'Square the round number.',
  		result: '70 ^ 2 = 4900'
  	,
  		text: 'Square the difference between the round number and the two numbers.',
  		result: ['70 - 67 = 3', '73 - 70 = 3', '3 ^ 2 = 9'].join("\n")
  	,
  		text: 'Subtract step 3 from step 2',
  		result: '4900 - 9 = 4891'
  	]
  ,
  	title: 'Divide any number by 5',
  	description: 'Quickly divide any number by five.',
  	example: '223 / 5 = 44.6',
  	steps: [
  		text: 'Multiply the number by 2.',
  		result: '223 x 2 = 446'
  	,
  		text: 'Move the decimal point to the left by one place',
  		result: '44.6'
  	]
  ,
  	title: 'Multiply by 11',
  	description: 'Easily multiply any two-digit number by eleven.',
  	example: '39 x 11 = 429',
  	steps: [
  		text: 'Add together the digits of the number being multiplied.',
  		result: '3 + 9 = 12'
  	,
  		text: 'Place a zero between the two digits of the number being multiplied.',
  		result: '3<u>0</u>9'
  	,
  		text: 'Add the result from step 1 to the zero in the number from step 2. Don\'t forget to carry the 1 if there is one.',
  		result: [" 309 ",
  						 "<em>+12 </em>",
  						 " 429"].join("\n")
  	]
  ,
  	title: 'Multiply in the 90\'s',
  	description: 'Quickly multiply together two numbers that are in the nineties.'
  	example: '97 x 92 = 8924',
  	steps: [
  		text: 'Find the difference between each number and 100.',
  		result: ['100 - 97 = 3', '100 - 92 = 8'].join("\n")
  	,
  		text: 'Add together the numbers from step 1.',
  		result: '3 + 8 = 11'
  	,
  		text: 'Subtract the result from step 2 from 100.',
  		result: '100 - 11 = 89'
  	,
  		text: 'Multiply together the two numbers from step 1.',
  		result: '3 x 8 = 24'
  	,
  		text: 'Put the answer from step 4 behind the answer from step 3.',
  		result: '"89" + "24" = 8924'
  	]
  ,
  	title: 'Square numbers in the 50\'s',
  	description: 'Easily square numbers in the fifties.',
  	example: '53 ^ 2 = 2809',
  	steps: [
  		text: 'Add the ones digit from the number to 25.',
  		result: '25 + 3 = 28'
  	,
  		text: 'Square the ones digit',
  		result: '3 ^ 2 = <em>09</em>',
  		note: 'If less than 10, prepend it with 0.'
  	,
  		text: 'Put the answer in step 2 behind the answer from step 1.',
  		result: '"28" + "09" = 2809'
  	]
  ,
  	title: 'Multiply differing by 2, 4 and 6',
  	description: 'Multiply two numbers that differ by 2, 4 or 6 by using their average.',
  	example: '22 x 18',
  	steps: [
  		text: 'Identify the average of the two numbers. This will be a number that sits halfway between the two numbers.',
  		result: '18->19-><em>20</em><-21<-22'
  	,
  		text: 'Square the average found in step 1.',
  		result: '20 ^ 2 = 400'
  	,
  		text: 'If the numbers differ by:<ul><li><strong>2:</strong> subtract 1 from step 2</li><li><strong>4:</strong> subtract 4 from step 2</li><li><strong>6:</strong> subtract 9 from step 2</li></ul>',
  		result: '400 - 4 = 396'
  	]
  ,
  	title: 'Multiply if 1\'s sum is 10',
  	description: 'Multiply two numbers whose first number is the same and whose ones digits sum to ten.',
  	example: '49 x 41 = 2009',
  	steps: [
  		text: 'Multiply the tens place digit by itself plus one.',
  		result: '4 x 5 = 20'
  	,
  		text: 'Multiply the ones place digits together.',
  		result: '9 x 1 = <em>09</em>',
  		note: 'If less than 10, prepend it with 0.'
  	,
  		text: 'Place the result from step 1 in front of the result from step 2.',
  		result: '"20" + "09" = 2009'
  	]
  ,
  	title: 'Multiply two close numbers',
  	description: 'Multiply two numbers differing by a small amount.',
  	example: '44 x 43 = 1892',
  	steps: [
  		text: 'Square the lowest number.',
  		result: '43 ^ 2 = 1849'
  	,
  		text: 'Multiply the lowest number by the difference between the two numbers.',
  		result: '43 x 1 = 43'
  	,
  		text: 'Add the results of steps 1 and 2.',
  		result: '1849 + 43 = 1892'
  	]
  ,
  	title: 'Sum of first n even numbers',
  	description: 'Sum the first n even numbers in a series.',
  	example: '2 + 4 + 6 + ... + 122 = 3782',
  	steps: [
  		text: 'Divide the highest number in the series by 2.',
  		result: '122 / 2 = 61'
  	,
  		text: 'Multiply the result of step 1 by itself plus one.',
  		result: '61 x 62 = 3782'
  	]
  ,
  	title: 'Sum of first n odd numbers',
  	description: 'Sum the first n odd numbers in a series.',
  	example: '1 + 3 + 5 + ... + 123 = 3844',
  	steps: [
  		text: 'Add one to the highest number and divide by two.',
  		result: ['123 + 1 = 124',
  						 '124 / 2 = 62'].join("\n")
  	,
  		text: 'Square the result of step 1.',
  		result: '62 ^ 2 = 3844'
  	]
  ,
	],
	'turbo-boost': [
		title: 'Nines complement',
		description: 'The nines complement is the number needed to make a single digit add up to 9. This technique is a building block for use in other tricks.',
		example: '9\'s complement of 7? = 2',
		steps: [
			text: 'Subtract the number that you are finding the 9\'s complement of from 9.',
			result: '9 - 7 = 2',
			note: 'This technique can be used with any large number. Simply take the 9\'s complement of each digit to find the 9\'s complement of the entire number.',
		,
			text: 'Subtract each digit in the number from 9.',
			result: ['9 - 6 = 3',
							 '9 - 3 = 6',
							 '9 - 4 = 5',
							 '9 - 7 = 2',
							 '   = 3652'].join("\n")
		]
	,
		title: 'Tens complement',
		description: 'The tens complement is the number needed to make a single digit add up to 10. This technique is a building block for use in other tricks.',
		example: '10\'s complement of 7? = 3',
		steps: [
			text: 'Subtract the number that you are finding the 10\'s complement of from 10.',
			result: '10 - 7 = 3',
			note: 'This technique can be used with any large number. Simply take the 10\'s complement of each digit to find the 10\'s complement of the entire number.',
		,
			text: '10\'s complement of 6347?',
			result: ['10 - 6 = 4',
							 '10 - 3 = 7',
							 '10 - 4 = 6',
							 '10 - 7 = 3',
							 '    = 4763'].join("\n")
		]
	
	]
}

# Loop through all the sections data
for category in Mathem.categories
	sectionsData[category.slug] = sectionsData[category.slug] || []
	for section, index in sectionsData[category.slug]
		category.addSection(section)

# Get a single category object by name, slug, or id
Mathem.getCategory = (search) ->
	for category in Mathem.categories
		if category.match(search)?
			return category

# Build DOM
Mathem.CategoryLinkTemplate = Hogan.compile('<li><a href="{{selector}}">{{name}}</a></li>')
Mathem.CategoryTemplate = Hogan.compile('<div class="row-fluid primary-tab" id="{{slug}}-content"><div class="span12"><div class="span3"><ul class="nav nav-list"></ul></div><div class="span9"><div class="tabs-content"></div></div></div></div>')
Mathem.SectionLinkTemplate = Hogan.compile('<li><a href="{{selector}}">{{title}} <i class="icon-chevron-right"></i></a></li>')

Mathem.initialize = () ->
	categoryNav = $ '#category-nav'
	categoryContainer = $ '#categories-container'
	for category in Mathem.categories
		categoryNav.append(Mathem.CategoryLinkTemplate.render
			selector: category.selector(),
			name: category.name
		)

		categoryContainer.append(Mathem.CategoryTemplate.render({slug: category.slug}))
		categoryContentContainer = $ category.selector()

		categorySectionNav = categoryContentContainer.find('ul.nav')
		categorySectionNav.affix({
			offset: {
				top: 0,
				bottom: 60
			}
		});
		categorySectionNav.scrollspy({
			offset: 0
		});
		categorySectionContainer = categoryContentContainer.find('div.tabs-content')
		for section in category.getSections()
			categorySectionNav.append(Mathem.SectionLinkTemplate.render
				selector: section.selector()
				title: section.title
			)
			categorySectionContainer.append(section.render())
			categorySectionStepsContainer = categoryContainer.find(section.selector()).find('.steps')
			for step in section.getSteps()
				categorySectionStepsContainer.append(step.render())

	$('[data-spy="affix"]').each () ->
	  $(this).affix('refresh')

	`$.easing.elasout = function(x, t, b, c, d) {
		var s=1.70158;var p=0;var a=c;
		if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
		if (a < Math.abs(c)) { a=c; var s=p/4; }
		else var s = p/(2*Math.PI) * Math.asin (c/a);
		return a*Math.pow(2,-10*t) * Math.sin( (t*d-s)*(2*Math.PI)/p ) + c + b;
	};`

	# Bind events
	categoryNav.on 'click', 'a', (e) ->
		e.preventDefault()
		category = Mathem.getCategory($(this).attr('href'))
		# Show category contents
		if category.getSections().length > 0
			# Update affix
			parent = $(this).parent()
			parent.siblings().removeClass 'active'
			parent.addClass 'active'
			content = $(category.selector())
			content.siblings().fadeOut();
			content.fadeIn();
			$("a[href=#{category.getSections()[0].selector()}]").click()

	for category in Mathem.categories
		categorySectionNav = $ category.selector() + ' ul.nav'
		categorySectionNav.on 'click', 'a', (e) ->
			self = $ this
			e.preventDefault()
			parent = self.parent()
			parent.addClass 'active'
			parent.siblings().removeClass 'active'
			$.scrollTo(
				$(self.attr('href')),
				250
			);

	$(categoryNav).find('a').first().click()
	$("a[href=#{Mathem.categories[0].getSections()[0].selector()}]").click()

	window.setTimeout () ->
		($ 'body').fadeIn('slow')
	, 1
