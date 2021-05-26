module.exports = {
  //mode: "jit",
  purge: [
    "../lib/**/*.ex",
    "../lib/**/*.leex",
    "../lib/**/*.eex",
    "./js/**/*.js",
  ],
  darkMode: false,
  important: true,
  theme: {
    extend: {
      typography: () => ({
        DEFAULT: {
          css: {
            color: 'white',
            a: {
              color: 'white',
            },
          },
        },
      })
    },
  },
  variants: {
    extend: {},
  },
  plugins: [
    require("@tailwindcss/forms"),
    require('@tailwindcss/typography'),
  ],
}
