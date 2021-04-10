// Initial data passed to Elm (should match `Flags` defined in `Shared.elm`)
// https://guide.elm-lang.org/interop/flags.html

const translations = fetch('/translations/translations.de.json').then(resp => resp.json()).then(resp => {
  var flags = { width: window.innerWidth, height: window.innerHeight, translations: resp };

  // Start our Elm application
  var app = Elm.Main.init({ flags: flags });
  console.log(flags)

  // Ports go here
  // https://guide.elm-lang.org/interop/ports.html
  app.ports.deleteCookie.subscribe(() => {
    document.cookie = "hw_session=; expires=Thu, 01 Jan 1970 00:00:01 GMT";
  });
})

