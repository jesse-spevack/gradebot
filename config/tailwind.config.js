module.exports = {
  content: [
    './app/views/**/*.{erb,haml,html,slim}',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['DM Sans', 'system-ui', 'sans-serif'],
        display: ['Fraunces', 'serif']
      },
      fontSize: {
        'mega': ['20rem', { lineHeight: '1' }],
        'super': ['25rem', { lineHeight: '1' }]
      }
    }
  },
  plugins: []
}
