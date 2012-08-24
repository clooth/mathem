`(function(a){a.fn.extend({outerHTML:function(b){if(!this.length)return null;else if(b===undefined){var c=this.length?this[0]:this,d;if(c.outerHTML)d=c.outerHTML;else d=a(document.createElement("div")).append(a(c).clone()).html();if(typeof d==="string")d=a.trim(d);return d}else if(a.isFunction(b)){this.each(function(c){var d=a(this);d.outerHTML(b.call(this,c,d.outerHTML()))})}else{var e=a(this),f=[],g=a(b),h;for(var i=0;i<e.length;i++){h=g.clone(true);e.eq(i).replaceWith(h);for(var j=0;j<h.length;j++)f.push(h[j])}return f.length?a(f):null}}})})(jQuery);`

String::slugify = () ->
	@trim().replace(/[\s,']+/g, '-').toLowerCase()

String::unSelectorize = () ->
	@replace('#', '')

Mathem = {}

class SectionStep
	# Markup template for a step
	@template = ['<li class="step clearfix" id="{{slug}}">',
				 '<div class="index">Step {{id}}.</div>',
				 '<div class="title">{{text}}</div>',
				 '<div class="result {{plain}}">{{{result}}}</div>',
				 '</li>'].join('')

	constructor: (@id, @text, @result, @plain) ->
		@slug = @id
		@plain = if @plain then 'plain' else 'math'

	setSection: (@section) ->
		@slug = @section.slug + '-' + @slug

	render: () ->
		template = Hogan.compile(SectionStep.template)
		@markup = template.render
			id: @id
			slug: @slug,
			text: @text,
			result: @result,
			plain: @plain
		@markup

	selector: () ->
		'#' + @slug

class Section
	@template = ['<section class="tab-pane section" id="{{slug}}">',
							   '<h2>{{title}}</h2>',
							   '<p class="lead">{{description}}<br />'
							   '<strong>Example:</strong> <span class="example math">{{example}}</span>',
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
		stepObj = new SectionStep(@steps.length+1, step.text, step.result, step.plain)
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
		if @slug is search or @name is search or @id is search or @selector() is search
			return true
		false

	selector: () ->
		'#' + @slug

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
		{
			title: 'Multiply as high as 19x19',
			description: 'Quickly multiply any two two-digit numbers up to 19 x 19',
			example: '17 x 12 = 204',
			steps: [
				{
					text: "Add the one's place digit form the smaller number to the larger number.",
					result: "17 + 2 = 19"
				},
				{
					text: "Add a zero to the end.",
					result: "\"19\" + \"0\" = 190",
					plain: true
				},
				{
					text: "Multiply the one's place digit of the two numbers.",
					result: "7 x 2 = 14"
				},
				{
					text: "Add the results of steps 2 and 3 for the answer.",
					result: "190 + 14 = 204"
				}
			]
		},
		{
			title: 'Foobar',
			description: 'Barfoo',
			example: 'barf lol + 1',
			steps: []
		}
	]
}

# Loop through all the sections data
for category in Mathem.categories
	sectionsData[category.slug] = sectionsData[category.slug] || []
	for section, index in sectionsData[category.slug]
		category.addSection(section)

# Get a single category object by name, slug, or id
Mathem.getCategory = (category) ->
	for category in Mathem.categories
		if category.match(category)?
			return category

# Build DOM
Mathem.CategoryLinkTemplate = Hogan.compile('<li><a href="{{selector}}" data-toggle="tab">{{name}}</a></li>')
Mathem.CategoryTemplate = Hogan.compile('<div class="span12 tab-pane primary-tab" id="{{slug}}"><div class="tabbable tabs-left"><div class="span3"><ul class="nav nav-pills nav-stacked"></ul></div><div class="span9"><div class="tab-content"></div></div></div></div>')
Mathem.SectionLinkTemplate = Hogan.compile('<li><a href="{{selector}}" data-toggle="tab">{{title}} <i class="icon-chevron-right"></i></a></li>')

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
		categorySectionContainer = categoryContentContainer.find('div.tab-content')
		for section in category.getSections()
			categorySectionNav.append(Mathem.SectionLinkTemplate.render
				selector: section.selector()
				title: section.title
			)
			categorySectionContainer.append(section.render())
			categorySectionStepsContainer = categoryContainer.find(section.selector()).find('.steps')
			for step in section.getSteps()
				categorySectionStepsContainer.append(step.render())

	# Bind events
	categoryNav.on 'click', 'a', (e) ->
		category = Mathem.getCategory($(this).attr('href'))
		($ "a[href=#{category.getSections()[0].selector()}]").click()



	null
