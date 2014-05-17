module.exports = function(app){
  var nowjs = require('now')
  var everyone = nowjs.initialize(app);
  return {
      everyone: everyone,
      nowjs : nowjs
    };
}
