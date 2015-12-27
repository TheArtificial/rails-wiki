// inserts text at cursor, or before and after selection
// based on http://stackoverflow.com/a/12815163/5610
jQuery.fn.extend({
  inject: function(insertTextPre, insertTextPost){
    return this.each(function(i) {
      if (document.selection) {
        // IE
        this.focus();
        sel = document.selection.createRange();
        sel.text = insertTextPre + insertTextPost;
        this.focus();
      }
      else if (this.selectionStart || this.selectionStart == '0') {
        // modern browser
        var startPos = this.selectionStart;
        var endPos = this.selectionEnd;
        var scrollTop = this.scrollTop;
        this.value = this.value.substring(0,     startPos)+insertTextPre+this.value.substring(startPos,endPos)+insertTextPost+this.value.substring(endPos,this.value.length);
        this.focus();
        this.selectionStart = startPos + insertTextPre.length;
        this.selectionEnd = ((startPos + insertTextPre.length) + this.value.substring(startPos,endPos).length);
        this.scrollTop = scrollTop;
      } else {
        // no selection, only use prefix
        if (document.queryCommandSupported('insertText')) {
            document.execCommand('insertText', false, text);
        } else {
          this.value += insertTextPre;
          this.focus();
        }
      }
    })
  }
});
