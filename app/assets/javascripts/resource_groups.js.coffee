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
    $(theGraph).find('.network-graph-canvas').each (i, e) =>
      sigInst = sigma.init(e).drawingProperties({
        defaultLabelColor: '#fff',
        defaultEdgeType: 'curve'
      }).graphProperties({
        minNodeSize: 1,
        maxNodeSize: 10
      });

      sigInst.parseJson($(e).attr('data-graph-url'));
      sigInst.draw();

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