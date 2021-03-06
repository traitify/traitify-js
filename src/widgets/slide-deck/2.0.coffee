Traitify.ui.slideDeck = (assessmentId, selector, options)->
  Builder = Object()
  Builder.nodes = Object()
  Builder.states = Object()
  Builder.states.animating = false
  Builder.data = Object()
  Builder.data.slideResponses = Object()
  Builder.states.finished = false

  if typeof options == "undefined"
    options = Object()

  if navigator.userAgent.match(/iPad/i)
    Builder.device = "ipad"

  if navigator.userAgent.match(/iPhone/i)
   Builder.device = "iphone"

  if navigator.userAgent.match(/Android/i)
    Builder.device = "android"

  if navigator.userAgent.match(/BlackBerry/i)
    Builder.device = "blackberry"

  if navigator.userAgent.match(/webOS/i)
    Builder.device = "webos"

  if typeof selector != "string"
    Builder.nodes.main = document.createElement("div")
    document.getElementsByTagName("body")[0].appendChild(Builder.nodes.main)
  else if  selector.indexOf("#") != -1
    selector = selector.replace("#", "")
    Builder.nodes.main = document.getElementById(selector)
  else
    selector = selector.replace(".", "")
    selectedObject = document.getElementsByClassName(selector)
    Builder.nodes.main = if selectedObject then selectedObject[0] else null

  if !Builder.nodes.main
    console.log("YOU MUST HAVE A TAG WITH A SELECTOR FOR THIS TO WORK")
    return false

  Builder.data.slidesLeft = ->
    Builder.data.slides.length - Builder.data.currentSlide

  Builder.data.slideValues = Array()
  # LOCAL DB FOR SLIDES
  Builder.data.addSlide = (id, value)->
    Builder.data.lastSlideTime = Builder.data.currentSlideTime
    Builder.data.currentSlideTime = new Date().getTime()
    Builder.data.slideValues.push({
      id: id, 
      response: value, 
      time_taken: Builder.data.currentSlideTime - Builder.data.lastSlideTime
    })
    Builder.data.sentSlides += 1
    if Builder.data.slideValues.length % 10 == 0 || Builder.data.sentSlides == Builder.data.slidesToPlayLength
      Traitify.addSlides(assessmentId, Builder.data.slideValues, (response)->
        if Builder.callbacks.addSlide
          Builder.callbacks.addSlide(Builder)
        if Builder.data.sentSlides == Builder.data.slidesToPlayLength
          Builder.nodes.main.innerHTML = ""
          if options.showResults != false
            Traitify.ui.resultsDefault(assessmentId, selector, options)
          if Builder.callbacks.finished
            Builder.callbacks.finished(Builder)
      )

  # VIEW LOGIC
  Builder.partials = Object()
  Builder.partials.make = (elementType, attributes)->
    element = document.createElement(elementType)

    for attributeName of attributes
      element.setAttribute(attributeName, attributes[attributeName])

    element

  Builder.partials.div = (attributes)->
    @make("div", attributes)

  Builder.partials.img = (attributes)->
    @make("img", attributes)

  Builder.partials.i = (attributes)->
    @make("i", attributes)

  Builder.data.getProgressBarNumbers = (initialize)->
    slideLength = Builder.data.totalSlideLength 
    currentLength = Builder.data.slides.length 
    currentPosition = Builder.data.sentSlides
    unless initialize == "initializing"
      currentPosition += 1

    value = slideLength - currentLength + currentPosition
    (value / Builder.data.totalSlideLength) * 100

  Builder.partials.slideDeckContainer = ->
    slidesContainer = @div({class:"tf-slide-deck-container"})
    cover = @div({class:"cover"})
    cover.innerHTML = "Landscape mode is not currently supported"
    slidesContainer.appendChild(cover)
    
    slidesLeft = Builder.data.getProgressBarNumbers("initializing")

    slidesContainer.appendChild(Builder.partials.progressBar(slidesLeft))

    slidesContainer.appendChild(@slides(Builder.data.slides))

    slidesContainer.appendChild(@meNotMe())
    slidesContainer

  Builder.partials.meNotMe = ->
    meNotMeContainer = @div({class:"me-not-me-container"})
    Builder.nodes.me = @div({class:"me"})
    Builder.nodes.notMe = @div({class:"not-me"})
    Builder.nodes.notMe.innerHTML = "Not Me"
    Builder.nodes.me.innerHTML = "Me"
    meNotMeContainer.appendChild(Builder.nodes.me)
    meNotMeContainer.appendChild(Builder.nodes.notMe)
    Builder.nodes.meNotMeContainer = meNotMeContainer

    meNotMeContainer

  Builder.partials.slides = (slidesData)->
    slides = @div({class:"slides"})
    placeHolderSlide = Builder.partials.slide(slidesData[0])
    placeHolderSlide.className += " placeholder"
    slides.appendChild(placeHolderSlide)

    Builder.nodes.currentSlide = Builder.partials.slide(slidesData[0])
    Builder.nodes.currentSlide.className += " active"
    slides.appendChild(Builder.nodes.currentSlide)

    if slidesData[1]
      Builder.nodes.nextSlide = Builder.partials.slide(slidesData[1])
      slides.appendChild(Builder.nodes.nextSlide)
    else
      Builder.nodes.nextSlide = false

    Builder.nodes.slides = slides

    slides

  Builder.partials.slide = (slideData)->
    slide = @div({class:"slide"})
    slideCaption = @div({class:"caption"})
    slideCaption.innerHTML = slideData.caption

    if Builder.device
        slideImg = @div({
          style:"background-image:url('#{slideData.image_desktop_retina}'); background-position:#{slideData.focus_x}% #{slideData.focus_y}%;'", 
          class:"image"
        })
        slideImg.appendChild(slideCaption)
    else
        slideImg = @img({src:slideData.image_desktop_retina})
        slide.appendChild(slideCaption)

    slide.appendChild(slideImg)
    slide

  Builder.partials.progressBar = (percentFinished)->
    progressBar = @div({class:"progress-bar"})
    progressBarInner = @div({class:"progress-bar-inner"})
    progressBarInner.style.width = percentFinished + "%"
    progressBar.appendChild(progressBarInner)

    Builder.nodes.progressBar = progressBar
    Builder.nodes.progressBarInner = progressBarInner

    progressBar

  Builder.partials.loadingAnimation = ()->
    loadingContainer = @div({class:"loading"})
    leftDot = @i(Object())
    rightDot = @i(Object())
    loadingSymbol = @div({class:"symbol"})
    loadingSymbol.appendChild(leftDot)
    loadingSymbol.appendChild(rightDot)
    loadingContainer.appendChild(loadingSymbol)

    loadingContainer

  Builder.helpers = Object()
  touched = Object()
  Builder.helpers.touch = (touchNode, callBack)->
    touchNode.addEventListener('touchstart', (event)->
      touchobj = event.changedTouches[0]
      touched.startx = parseInt(touchobj.clientX)
      touched.starty = parseInt(touchobj.clientY)
      
    )
    touchNode.addEventListener('touchend', (event)->
      touchobj = event.changedTouches[0]
      touchDifferenceX = Math.abs(touched.startx - parseInt(touchobj.clientX))
      touchDifferenceY = Math.abs(touched.starty - parseInt(touchobj.clientY))
      if (touchDifferenceX < 2 && touchDifferenceX < 2)   
        callBack()
    )
  Builder.helpers.onload = (callBack)->
    if (window.addEventListener)
        window.addEventListener('load', callBack)
    else if (window.attachEvent)
        window.attachEvent('onload', callBack)

  Builder.actions = ->
    if Builder.device == "iphone"  ||  Builder.device == "ipad" 
      Builder.helpers.touch(Builder.nodes.notMe, ->
        Builder.events.notMe()
      )
      Builder.helpers.touch(Builder.nodes.me, ->
        Builder.events.me()
      )
    else
      Builder.nodes.notMe.onclick = ->
        Builder.events.notMe()

      Builder.nodes.me.onclick = ->
        Builder.events.me()
    

  Builder.events = Object()

  Builder.events.me = ->
    if !Builder.states.animating && !Builder.data.slidesLeft() != 1
      if !Builder.data.slides[Builder.data.currentSlide] 
        Builder.events.loadingAnimation()

      Builder.states.animating = true
      Builder.events.advanceSlide()

      currentSlide = Builder.data.slides[Builder.data.currentSlide - 1]

      Builder.data.addSlide(currentSlide.id, true)

      Builder.data.currentSlide += 1

      if Builder.callbacks.me
        Builder.callbacks.me(Builder)

  Builder.events.notMe = ->
    if !Builder.states.animating && Builder.nodes.nextSlide
      if !Builder.data.slides[Builder.data.currentSlide] 
        Builder.events.loadingAnimation()

      Builder.states.animating = true
      Builder.events.advanceSlide()

      currentSlide = Builder.data.slides[Builder.data.currentSlide - 1]

      Builder.data.addSlide(currentSlide.id, false)

      Builder.data.currentSlide += 1

      if Builder.callbacks.notMe
        Builder.callbacks.notMe(Builder)

  Builder.events.advanceSlide = ->
    Builder.prefetchSlides()
    Builder.nodes.progressBarInner.style.width = Builder.data.getProgressBarNumbers() + "%"


    if Builder.nodes.playedSlide
      # REMOVE NODE
      Builder.nodes.slides.removeChild(Builder.nodes.playedSlide)

    Builder.nodes.playedSlide = Builder.nodes.currentSlide

    Builder.nodes.currentSlide = Builder.nodes.nextSlide

    Builder.nodes.currentSlide.addEventListener('webkitTransitionEnd', (event)-> 
      if Builder.events.advancedSlide
        Builder.events.advancedSlide()
      Builder.states.animating = false
    , false )

    Builder.nodes.currentSlide.addEventListener('transitionend', (event)-> 
      if Builder.events.advancedSlide
        Builder.events.advancedSlide()
      Builder.states.animating = false
    , false )
  
    Builder.nodes.currentSlide.addEventListener('oTransitionEnd', (event)-> 
      if Builder.events.advancedSlide
        Builder.events.advancedSlide()
      Builder.states.animating = false
    , false )
  
    Builder.nodes.currentSlide.addEventListener('otransitionend', (event)-> 
      if Builder.events.advancedSlide
        Builder.events.advancedSlide()
      Builder.states.animating = false
    , false )
  
    Builder.nodes.playedSlide.className += " played"
    Builder.nodes.currentSlide.className += " active"

    
    # NEW NEXT SLIDE
    nextSlideData = Builder.data.slides[Builder.data.currentSlide + 1]
    if nextSlideData
      Builder.nodes.nextSlide = Builder.partials.slide(nextSlideData)
      Builder.nodes.slides.appendChild(Builder.nodes.nextSlide)

    if Builder.callbacks.advanceSlide
      Builder.callbacks.advanceSlide(Builder)

  Builder.events.loadingAnimation = ->
    Builder.nodes.meNotMeContainer.className += " hide"
    Builder.nodes.slides.removeChild(Builder.nodes.currentSlide)
    Builder.nodes.slides.insertBefore(Builder.partials.loadingAnimation(), Builder.nodes.slides.firstChild)

  Builder.imageCache = Object()
  Builder.prefetchSlides = (count)->
    start = Builder.data.currentSlide - 1
    end = Builder.data.currentSlide + 9

    for slide in Builder.data.slides.slice(start, end)
      unless Builder.imageCache[slide.image_desktop_retina]
        Builder.imageCache[slide.image_desktop_retina] = new Image()
        Builder.imageCache[slide.image_desktop_retina].src = slide.image_desktop_retina

  Builder.events.setContainerSize = ->
      width = Builder.nodes.main.scrollWidth
      Builder.nodes.container.className = Builder.nodes.container.className.replace(" medium", "")
      Builder.nodes.container.className = Builder.nodes.container.className.replace(" large", "")
      Builder.nodes.container.className = Builder.nodes.container.className.replace(" small", "")
      if width < 480
        Builder.nodes.container.className += " small"
      else if width < 768
        Builder.nodes.container.className += " medium"
      
  Builder.events.onRotate = (rotateEvent)->
    supportsOrientationChange = "onorientationchange" of window
    orientationEvent = (if supportsOrientationChange then "orientationchange" else "resize")
    window.addEventListener(orientationEvent, (event)->
      rotateEvent(event)
    , false)
          
  Builder.states.initialized = false
  Builder.initialize = ->
    Traitify.getSlides(assessmentId, (data)->
      Builder.data.currentSlide = 1
      Builder.data.totalSlideLength = data.length
      Builder.data.sentSlides = 0

      Builder.data.slides = data.filter((slide)->
        !slide.completed_at
      )
      Builder.data.slidesToPlayLength = Builder.data.slides.length

      style = Builder.partials.make("link", {href:"https://s3.amazonaws.com/traitify-cdn/assets/stylesheets/slide_deck.css", type:'text/css', rel:"stylesheet"})

      Builder.nodes.main.innerHTML = ""

      Builder.nodes.main.appendChild(style)

      if Builder.data.slides.length != 0
        Builder.nodes.container = Builder.partials.slideDeckContainer()
        if Builder.device
          Builder.nodes.container.className += " #{Builder.device}"
          Builder.nodes.container.className += " mobile phone"
          if options && options.nonTouch
            Builder.nodes.container.className += " non-touch"

        if options && options.size
          Builder.nodes.container.className += " #{options.size}"

        Builder.nodes.main.appendChild(Builder.nodes.container)

        Builder.actions()

        Builder.prefetchSlides()
        
        Builder.events.setContainerSize()
        
        window.onresize = ->
          if !Builder.device
            Builder.events.setContainerSize()
            
        if Builder.device && Builder.device
          
          setupScreen = ->
            windowOrienter = ->
                Builder.nodes.main.style.height = window.innerHeight + "px"
            windowOrienter()
              
            Builder.events.onRotate( (event)->
              windowOrienter()
            )

          Builder.helpers.onload( ->
            setupScreen()
          )
          setupScreen()
            
      else
        if typeof selector != "string"
            options.container = Builder.nodes.main
        if options && options.showResults != false
          Builder.results = Traitify.ui.resultsDefault(assessmentId, selector, options)
        
        if Builder.callbacks.finished
          Builder.states.finished = true
          Builder.callbacks.finished()
          
      
      if Builder.callbacks.initialize 
        Builder.callbacks.initialize(Builder)
      else
        Builder.states.initialized = true
      Builder.data.currentSlideTime = new Date().getTime()
    )

  Builder.callbacks = Object()
  Builder.onInitialize = (callBack)->
    if Builder.states.initialized == true
      callBack()
    Builder.callbacks.initialize = callBack
    Builder

  Builder.onFinished = (callBack)->
    if Builder.states.finished == true
      callBack()
    Builder.callbacks.finished = callBack
    Builder

  Builder.onAddSlide = (callBack)->
    Builder.callbacks.addSlide = callBack
    Builder

  Builder.onMe = (callBack)->
    Builder.callbacks.me = callBack
    Builder

  Builder.onNotMe = (callBack)->
    Builder.callbacks.notMe = callBack
    Builder

  Builder.onAdvanceSlide = (callBack)->
    Builder.callbacks.advanceSlide = callBack
    Builder

  Builder.initialize()
  
  Builder












#############################################################
#
# RESULTS WIDGET
#
#############################################################
Traitify.ui.resultsDefault = (assessmentId, selector, options)->
  console.log("here")
  Builder = Object()
