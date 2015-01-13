//JQuery Twitter Feed. Coded by Tom Elliott @ www.webdevdoor.com (2013) based on https://twitter.com/javascripts/blogger.js
//Requires JSON output from authenticating script: http://www.webdevdoor.com/php/authenticating-twitter-feed-timeline-oauth/

$(document).ready(function () {
  var displaylimit = 20;
  var showdirecttweets = false;
  var showretweets = true;
  var showtweetlinks = true;
  var showprofilepic = true;
	var showtweetactions = true;
	var showretweetindicator = true;
	
	$.getJSON('/feed/tumblr', function(feeds) {
		fetchFeed('tumblr', feeds);
	}).error(function(jqXHR, textStatus, errorThrown) {
		var error = "";
		if (jqXHR.status === 0) {
			error = 'Connection problem. Check file path and www vs non-www in getJSON request';
		} else if (jqXHR.status == 404) {
			error = 'Requested page not found. [404]';
		} else if (jqXHR.status == 500) {
			error = 'Internal Server Error [500].';
		} else if (exception === 'parsererror') {
			error = 'Requested JSON parse failed.';
		} else if (exception === 'timeout') {
			error = 'Time out error.';
		} else if (exception === 'abort') {
			error = 'Ajax request aborted.';
		} else {
			error = 'Uncaught Error.\n' + jqXHR.responseText;
		}	
		alert("error: " + error);
	});

	$.getJSON('/feed/facebook', function(feeds) {
		fetchFeed('facebook', feeds);
	}).error(function(jqXHR, textStatus, errorThrown) {
		var error = "";
		if (jqXHR.status === 0) {
			error = 'Connection problem. Check file path and www vs non-www in getJSON request';
		} else if (jqXHR.status == 404) {
			error = 'Requested page not found. [404]';
		} else if (jqXHR.status == 500) {
			error = 'Internal Server Error [500].';
		} else if (exception === 'parsererror') {
			error = 'Requested JSON parse failed.';
		} else if (exception === 'timeout') {
			error = 'Time out error.';
		} else if (exception === 'abort') {
			error = 'Ajax request aborted.';
		} else {
			error = 'Uncaught Error.\n' + jqXHR.responseText;
		}	
		alert("error: " + error);
	});

	$.getJSON('/feed/twitter', function(feeds) {
		fetchFeed('twitter', feeds);
	}).error(function(jqXHR, textStatus, errorThrown) {
		var error = "";
		if (jqXHR.status === 0) {
			error = 'Connection problem. Check file path and www vs non-www in getJSON request';
		} else if (jqXHR.status == 404) {
			error = 'Requested page not found. [404]';
		} else if (jqXHR.status == 500) {
			error = 'Internal Server Error [500].';
		} else if (exception === 'parsererror') {
			error = 'Requested JSON parse failed.';
		} else if (exception === 'timeout') {
			error = 'Time out error.';
		} else if (exception === 'abort') {
			error = 'Ajax request aborted.';
		} else {
			error = 'Uncaught Error.\n' + jqXHR.responseText;
		}	
		alert("error: " + error);
	});

	$.getJSON('/feed/instagram', function(feeds) {
		fetchFeed('instagram', feeds);
	}).error(function(jqXHR, textStatus, errorThrown) {
		var error = "";
		if (jqXHR.status === 0) {
			error = 'Connection problem. Check file path and www vs non-www in getJSON request';
		} else if (jqXHR.status == 404) {
			error = 'Requested page not found. [404]';
		} else if (jqXHR.status == 500) {
			error = 'Internal Server Error [500].';
		} else if (exception === 'parsererror') {
			error = 'Requested JSON parse failed.';
		} else if (exception === 'timeout') {
			error = 'Time out error.';
		} else if (exception === 'abort') {
			error = 'Ajax request aborted.';
		} else {
			error = 'Uncaught Error.\n' + jqXHR.responseText;
		}	
		alert("error: " + error);
	});

  var t = $('#feed').html();
  if (t == "") {
	//  $('#feed').html('Have you configured your <a href="/account">account</a>?');
	}

  function KetosItem(provider, f) {
		this.source = provider;
  	this.id = f.id;
		this.created_at = f.created_at;
		this.name = f.name;
		this.display_name = f.display_name;
		this.profile_image_url = f.profile_image_url;
		this.text = f.text;
    this.type = f.type;
		this.link = f.link;
		this.img_url = f.img_url;
		this.post_url = f.post_url;
		this.headerHtml = headerHtml;
		this.nameUrl = nameUrl;
		this.timeHtml = timeHtml;
		this.textHtml = textHtml;
		this.imgHtml = imgHtml;
    this.linkHtml = linkHtml;
		this.permaUrl = permaUrl;
		return this;
  }
  
  function headerHtml() {
		var output = '';
		if (this.source == 'twitter') {
      output += '<strong>tw</strong>'
			output += '<a href="'+this.nameUrl()+'">'
			output += '  <strong class="displayname">'+this.display_name+'</strong>';
			output += '  <span>&rlm;</span>';
			output += '  <span class="username">';
			output += '    <s>@</s><b>'+this.name+'</b>';
			output += '  </span>';
			output += '</a>';
		} else if (this.source == 'tumblr') {
			var s = '';
			if (this.title) {
				s = 'Source: <em>'+this.title+'</em>'
			}
      output += '<strong>tu</strong>'
			output += '<a href="'+this.nameUrl()+'">';
			output += '  <strong class="displayname">'+this.name+'</strong>';
			output += '  <span>&rlm;</span>';
			output += '  <span class="title">'+s+'</span>';
			output += '</a>';
    
		} else {
      if (this.source == "facebook") {
        output += '<strong>fb</strong>'					
			} else {
        output += '<strong>i</strong>'					
			}

			output += '<a href="'+this.nameUrl()+'">'
			output += '  <strong class="displayname">'+this.name+'</strong>';
			output += '  <span>&rlm;</span>';
			output += '  <span class="username">';
			output += '    &nbsp;';
			output += '  </span>';
			output += '</a>';
		}

		return output;
	}

	function nameUrl() {
		var output = '';
		if (this.source == 'twitter') {
			output += 'https://twitter.com/'+this.name;
		} else if (this.source == 'facebook') {
			var ids = this.id.split('_');
			output += 'https://www.facebook.com/'+ids[0];
		} else if (this.source == 'tumblr') {
			output += 'http://'+this.name+'.tumblr.com';
		} else if (this.source == 'instagram') {
			output += 'http://instagram.com/'+this.name;
		} else {
			output += this.name;
		}
		return output;
	}

	function timeHtml() {
		return '<small class="time"><a target="_blank" href="'+this.permaUrl()+'"><span>'+relative_time(this.created_at)+'</span></a></small>';
	}

	function textHtml() {
		s = this.text;

		if (this.source != 'tumblr') {
			s = addlinks(s);
		}

		return s;
	}

  function imgHtml() {
		return '<img src="'+this.img_url+'" />';
	}

  function linkHtml() {
		return '<iframe src="'+this.link+'" width="500" height="281" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>'
  }

	function permaUrl() {
		var output = '';
		if (this.source == 'twitter') {
			output += 'http://twitter.com/'+this.name+'/status/'+this.id;
		} else if (this.source == 'facebook') {
			var ids = this.id.split('_');
			output += 'https://www.facebook.com/'+ids[0]+'/posts/'+ids[1];
		} else if (this.source == 'tumblr') {
			output += this.post_url;
		} else if (this.source == 'instagram') {
			output += this.post_url;
		} else {
			output += this.name;
		}
		return output;
	}

	function fetchFeed(provider, feeds) {   
		var feedHTML = '';
		for (var i=0; i<feeds.length; i++) {
      console.log(feeds[i]);
			var f = $.parseJSON(feeds[i]);
      console.log(f.id);
			var kitem = KetosItem(provider, f);
			console.log(kitem.id);

			console.log(f);
					
			feedHTML += '<div class="stream-item" stamp="'+as_integer(kitem.created_at)+'">';
			feedHTML += '  <div class="stream-item-header">';
			feedHTML += '    '+kitem.headerHtml();
			feedHTML += '    '+kitem.timeHtml();
			feedHTML += '  </div>';
			feedHTML += '  <p class="stream-text">'+kitem.textHtml();
			if (kitem.img_url) {
				feedHTML += '<div class="media-container">'+kitem.imgHtml()+'</div>';
			}
			if (kitem.type == 'video') {
				feedHTML += '<div class="media-container">'+kitem.linkHtml()+'</div>';
			}
			feedHTML += '  </p>';
			feedHTML += '  <div class="stream-item-footer"></div>';
			feedHTML += '</div>';
			
		}
	

    feedHTML += $('#feed').html();
	  $('#feed').html(feedHTML);
	
    $('#feed').sortChildren(function(a, b) {
			return $(a).attr('stamp') < $(b).attr('stamp') ? 1 : -1;
		});

	}
	
	//Function modified from Stack Overflow
	function addlinks(data) {
		//Add link to all http:// links within tweets
		data = data.replace(/((https?|s?ftp|ssh)\:\/\/[^"\s\<\>]*[^.,;'">\:\s\<\>\)\]\!])/g, function(url) {
			return '<a href="'+url+'"  target="_blank">'+url+'</a>';
		});
		
		//Add link to @usernames used within tweets
//		data = data.replace(/\B@([_a-z0-9]+)/ig, function(reply) {
//			return '<a href="http://twitter.com/'+reply.substring(1)+'" style="font-weight:lighter;" target="_blank">'+reply.charAt(0)+reply.substring(1)+'</a>';
//		});
//		//Add link to #hastags used within tweets
//		data = data.replace(/\B#([_a-z0-9]+)/ig, function(reply) {
//			return '<a href="https://twitter.com/search?q='+reply.substring(1)+'" style="font-weight:lighter;" target="_blank">'+reply.charAt(0)+reply.substring(1)+'</a>';
//		});
		return data;
	}
	
	$.fn.sortChildren = function(compare) {
  var $children = this.children();
  $children.sort(compare);
  this.append($children);
  return this;
};

  function as_integer(created_at) {
	  var values = created_at.split(' ');
		var dvalues = values[0].split('-');
		var tvalues = values[1].split(':');

		var d = new Date(dvalues[0], dvalues[1]-1, dvalues[2], tvalues[0], tvalues[1], tvalues[2], "0");

		return d.getTime();
	}

	function relative_time(created_at) {
    var values = created_at.split(' ');
		var dvalues = values[0].split('-');
		var parsed_date = as_integer(created_at);

		var relative_to = new Date();
    var delta = parseInt((relative_to.getTime() - parsed_date) / 1000);
		var m_names = new Array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
		var shortdate = dvalues[2]+' '+m_names[dvalues[1]-1];
		delta = delta + (relative_to.getTimezoneOffset() * 60);
		
		if (delta < 60) {
			return delta.toString() + 's';
		} else if(delta < 120) {
			return '1m';
		} else if(delta < (60*60)) {
			return (parseInt(delta / 60)).toString() + 'm';
		} else if(delta < (120*60)) {
			return '1h';
		} else if(delta < (24*60*60)) {
			return (parseInt(delta / 3600)).toString() + 'h';
		} else if(delta < (48*60*60)) {
			//return '1 day';
			return shortdate;
		} else {
			return shortdate;
		}
	}

});