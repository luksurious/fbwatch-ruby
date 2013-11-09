$(document).ready ->
  $('.select2').each (i, e) =>
    select = $(e)
    options = 
      placeholder: select.data('placeholder')
    
    if select.hasClass('ajax')
      options.ajax = 
        url: select.data('source')
        dataType: 'json'
        data: (term, page) -> 
          q: term
          page: page
          per: 25
        results: (data, page) -> 
          results: data.resources
          more: data.total > (page * 25)

      options.dropdownCssClass = "bigdrop"

    select.select2(options)

  $('.network-graph').each ->
    theGraph = this
    $(theGraph).find('.network-graph-canvas').each (i, e) ->
      theContainer = this

      sigInst = sigma.init(e).drawingProperties({
        defaultLabelColor: '#fff',
        defaultEdgeType: 'curve'
      }).graphProperties({
        minNodeSize: 1,
        maxNodeSize: 10
      });

      sigInst.parseJson($(e).attr('data-graph-url'), ->
        sigInst.draw()
      )

      hideSmallEdges = (x) ->
        visible = 0
        sigInst.iterEdges (e) =>
          weight = e.weight || e.size
          if weight < x
            e.hidden = 1
          else
            e.hidden = 0
            visible += 1
        sigInst.draw()
        return visible

      $(theGraph).find('.network-graph-filter').change ->
        edgesCount = sigInst.getEdgesCount()
        if $(this).is(':checked')
          weight = 5
          while hideSmallEdges(weight) < (edgesCount / 10)
            weight -= 1
            if weight <= 1
              break
        else
          sigInst.iterEdges (e) =>
            e.hidden = 0
          sigInst.draw()
        return

      do ->
        popUp = null
     
        sigInst.bind('overnodes', (event) ->
          nodes = event.content
          neighborEdges = []

          sigInst.iterEdges( (e) ->
            if nodes.indexOf(e.source) >= 0 || nodes.indexOf(e.target) >= 0
              neighborEdges.push(
                to: if nodes.indexOf(e.source) >= 0 then e.target else e.source
                size: e.size
              )
            else
              e.hidden = 1
          ).draw(2, 2, 2)

          popUp && popUp.remove()

          node = false
          sigInst.iterNodes(
            (n) ->
              node = n
            [event.content[0]]
          )

          detailList = $('<ul>').append(
            $('<li>').text('Username: ' + node.id)
          ).append(
            $('<li>').text('Node size: ' + node.size)
          )

          $.each(neighborEdges, (index, value) ->
            detailList.append(
              $('<li>').text('Edge to: ' + value.to + ', weight: ' + value.size)
            )
          )

          popUp = $(
            '<div class="node-info-popup"></div>'
          ).append(
            detailList
          ).attr(
            'id',
            'node-info' + sigInst.getID()
          ).css(
            'left': node.displayX
            'top': node.displayY + 15
          )
     
          $(theContainer).append(popUp)
        ).bind('outnodes', (event) ->
          popUp && popUp.remove()
          popUp = false

          sigInst.iterEdges( (e) ->
            e.hidden = 0
          ).draw(2, 2, 2)
        ).draw()