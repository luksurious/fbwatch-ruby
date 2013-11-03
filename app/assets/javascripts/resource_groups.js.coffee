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

  $('.network-graph-canvas').each (i, e) =>
    sigInst = sigma.init(e).drawingProperties({
      defaultLabelColor: '#fff',
      defaultEdgeType: 'curve'
    }).graphProperties({
      minNodeSize: 1,
      maxNodeSize: 10
    });

    sigInst.parseJson($(e).attr('data-graph-url'));
    sigInst.draw();

    #theEdges = sigInst.getEdges()
    #theNodes = sigInst.getNodes()

    $('#network-graph-filter-edges').change ->
      if $(this).is(':checked')
        sigInst.iterEdges (e) =>
          weight = e.weight || e.size
          if weight < 5
            e.hidden = 1
      else
        sigInst.iterEdges (e) =>
          e.hidden = 0

      sigInst.draw()