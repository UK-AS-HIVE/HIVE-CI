Template.projectbar.helpers
  project: ->
    [{name: 'Projects', active: "active"}]
  active: ->
    if this.name is Session.get("projectName")
      return "active"
    else
      return null


