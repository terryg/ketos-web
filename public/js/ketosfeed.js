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
	
	var headerHTML = '';
	var loadingHTML = '';
	loadingHTML += '<div id="loading-container"><img src="images/ajax-loader.gif" width="32" height="32" alt="tweet loader" /></div>';
	
  $('#feed').html(headerHTML + loadingHTML);
	
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

  function KetosItem(provider, f) {
		this.source = provider;
		this.id = f.id;
		this.created_at = f.created_at;
		this.name = f.name;
		this.display_name = f.display_name;
		this.profile_image_url = f.profile_image_url;
		this.text = f.text;
		this.img_url = f.img_url;
		this.headerHtml = headerHtml;
		this.nameUrl = nameUrl;
		this.timeHtml = timeHtml;
		this.textHtml = textHtml;
		this.imgHtml = imgHtml;
		this.permaUrl = permaUrl;
		return this;
  }
  
  function headerHtml() {
		var output = '';
		if (this.source == 'twitter') {
			output += '<a href="'+this.nameUrl()+'">'
			output += '  <strong class="displayname">'+this.display_name+'</strong>';
			output += '  <span>&rlm;</span>';
			output += '  <span class="username">';
			output += '    <s>@</s><b>'+this.name+'</b>';
			output += '  </span>';
			output += '</a>';
		} else {
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
		} else {
			output += this.name;
		}
		return output;
	}

	function timeHtml() {
		return '<small class="time"><a href="'+this.permaUrl()+'"><span>'+relative_time(this.created_at)+'</span></a></small>';
	}

	function textHtml() {
		s = this.text;

		return s;
	}

  function imgHtml() {
		return '<img src="'+this.img_url+'" />';
	}

	function permaUrl() {
		var output = '';
		if (this.source == 'twitter') {
			output += 'http://twitter.com/'+this.name+'/status/'+this.id;
		} else if (this.source == 'facebook') {
			var ids = this.id.split('_');
			output += 'https://www.facebook.com/'+ids[0]+'/posts/'+ids[1];
		} else {	
			output += this.name;
		}
		return output;
	}

	function fetchFeed(provider, feeds) {   
		var feedHTML = '';
		for (var i=0; i<feeds.length; i++) {
			var f = $.parseJSON(feeds[i]);
			var kitem = KetosItem(provider, f);
			
			console.log(f);
					
			feedHTML += '<div class="stream-item">';
			feedHTML += '  <div class="stream-item-header">';
			feedHTML += '    '+kitem.headerHtml();
			feedHTML += '    '+kitem.timeHtml();
			feedHTML += '  </div>';
			feedHTML += '  <p class="stream-text">'+kitem.textHtml();
			if (kitem.img_url) {
				feedHTML += '<div class="media-container">'+kitem.imgHtml()+'</div>';
			}
			feedHTML += '  </p>';
			feedHTML += '  <div class="stream-item-footer"></div>';
			feedHTML += '</div>';
			
		}
	
		feedHTML += $('#feed').html();
		$('#feed').html(feedHTML);
	}
	
	//Function modified from Stack Overflow
	function addlinks(data) {
		//Add link to all http:// links within tweets
		data = data.replace(/((https?|s?ftp|ssh)\:\/\/[^"\s\<\>]*[^.,;'">\:\s\<\>\)\]\!])/g, function(url) {
			return '<a href="'+url+'"  target="_blank">'+url+'</a>';
		});
		
		//Add link to @usernames used within tweets
		data = data.replace(/\B@([_a-z0-9]+)/ig, function(reply) {
			return '<a href="http://twitter.com/'+reply.substring(1)+'" style="font-weight:lighter;" target="_blank">'+reply.charAt(0)+reply.substring(1)+'</a>';
		});
		//Add link to #hastags used within tweets
		data = data.replace(/\B#([_a-z0-9]+)/ig, function(reply) {
			return '<a href="https://twitter.com/search?q='+reply.substring(1)+'" style="font-weight:lighter;" target="_blank">'+reply.charAt(0)+reply.substring(1)+'</a>';
		});
		return data;
	}
	
	
	function relative_time(created_at) {
		var values = created_at.split(' ');
		var dvalues = values[0].split('-');
		var tvalues = values[1].split(':');

		var parsed_date = Date.parse(dvalues[0], dvalues[1], dvalues[2], tvalues[0], tvalues[1], tvalues[2]);

		var relative_to = new Date();
		var delta = parseInt((relative_to.getTime() - parsed_date) / 1000);
		var m_names = new Array('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
		var shortdate = dvalues[2]+' '+m_names[dvalues[1]-1];
		delta = delta - (relative_to.getTimezoneOffset() * 60);
		
		if (delta < 60) {
			return '1m';
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

});q