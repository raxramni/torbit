//= require webshims/polyfiller
// https://github.com/whatcould/webshims-rails#note-on-changes-in-rails-4
// Don't forget "rake webshims:update_public" which will copy all assets not integrated into pipeline into public dir
$.webshims.setOptions({basePath: '/webshims/shims/'});
$.webshims.polyfill('forms forms-ext');
