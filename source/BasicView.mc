using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.Timer as Timer;
using Toybox.Communications as Comm;
using Toybox.Math as Math;
using Toybox.Position as Position;

enum {
  SCREEN_SHAPE_CIRC = 0x000001,
  SCREEN_SHAPE_SEMICIRC = 0x000002,
  SCREEN_SHAPE_RECT = 0x000003
}

class BasicView extends Ui.WatchFace {

    // globals
    var debug = true;
    var timer1;
    var delay = 0;
    var timer_timeout = 4000;
    var timer_steps = timer_timeout;
    var timer_fast = 200;
    var tweets = [];

    // sensors / status
    var battery = 0;
    var bluetooth = true;

    // time
    var hour = null;
    var minute = null;
    var day = null;
    var day_of_week = null;
    var month_str = null;
    var month = null;

    // layout
    var vert_layout = false;
    var canvas_h = 0;
    var canvas_w = 0;
    var canvas_shape = 0;
    var canvas_rect = false;
    var canvas_circ = false;
    var canvas_semicirc = false;
    var canvas_tall = false;
    var canvas_r240 = false;

    // settings
    var set_leading_zero = false;
    var current_tweet = 0;

    // fonts

    // bitmaps
    var weather_main = null;
    var got_tweets = null;
    var sent_request = null;
    var f_opensans = null;
    var degreeStart = 0;
    var gciqlogo = null;


    // animation settings


    function initialize() {
    }

    function onLayout(dc) {

      // w,h of canvas
      canvas_w = dc.getWidth();
      canvas_h = dc.getHeight();

      // check the orientation
      if ( canvas_h > (canvas_w*1.2) ) {
        vert_layout = true;
      } else {
        vert_layout = false;
      }

      // let's grab the canvas shape
      var deviceSettings = Sys.getDeviceSettings();
      canvas_shape = deviceSettings.screenShape;

      if (debug) {
        Sys.println(Lang.format("canvas_shape: $1$", [canvas_shape]));
      }

      // find out the type of screen on the device
      canvas_tall = (vert_layout && canvas_shape == SCREEN_SHAPE_RECT) ? true : false;
      canvas_rect = (canvas_shape == SCREEN_SHAPE_RECT && !vert_layout) ? true : false;
      canvas_circ = (canvas_shape == SCREEN_SHAPE_CIRC) ? true : false;
      canvas_semicirc = (canvas_shape == SCREEN_SHAPE_SEMICIRC) ? true : false;
      canvas_r240 =  (canvas_w == 240 && canvas_w == 240) ? true : false;

      // set offsets based on screen type
      // positioning for different screen layouts
      if (canvas_tall) {
        gciqlogo = Ui.loadResource(Rez.Drawables.gciqlogo_sml);
      }
      if (canvas_rect) {
        gciqlogo = Ui.loadResource(Rez.Drawables.gciqlogo_sml);
      }
      if (canvas_circ) {
        if (canvas_r240) {
          gciqlogo = Ui.loadResource(Rez.Drawables.gciqlogo);
        } else {
          gciqlogo = Ui.loadResource(Rez.Drawables.gciqlogo);
        }
      }
      if (canvas_semicirc) {
        gciqlogo = Ui.loadResource(Rez.Drawables.gciqlogo);
      }



    }


    //! Called when this View is brought to the foreground. Restore
    //! the state of this View and prepare it to be shown. This includes
    //! loading resources into memory.
    function onShow() {

    }

    // onReceiveTweetData
    // callback used to store data, and trigger a UI update via the got_tweets flag
    function onReceiveTweetData(responseCode, data) {

      if (debug) {
        Sys.println(Lang.format("responseCode: $1$", [responseCode]));
      }

      if (responseCode == 200) {
        if (debug) {
          Sys.println(Lang.format("tweets: $1$", [data]));
        }
        tweets = data;

        // set the got_tweets flag
        got_tweets = true;
      }

    }

    //! Update the view
    function onUpdate(dc) {

      // grab battery
      var stats = Sys.getSystemStats();
      var batteryRaw = stats.battery;
      battery = batteryRaw > batteryRaw.toNumber() ? (batteryRaw + 1).toNumber() : batteryRaw.toNumber();

      // do we have bluetooth?
      var deviceSettings = Sys.getDeviceSettings();
      bluetooth = deviceSettings.phoneConnected;

      // clear the screen
      dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_WHITE);
      dc.clear();

      // w,h of canvas
      var dw = dc.getWidth();
      var dh = dc.getHeight();

      if (got_tweets != null) {

          // parse tweet data
          var this_tweet = tweets[current_tweet%tweets.size()];
          var tweet = this_tweet["text"];
          var username = this_tweet["user"];


          // font for screen
          var font = Gfx.FONT_SYSTEM_TINY;
          var font_height = dc.getFontHeight(font);


          // draw username
          dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_TRANSPARENT);
          dc.drawText(dw/2,20,font, username ,Gfx.TEXT_JUSTIFY_CENTER);


          // setup to render a multiline text field
          var length_of_tweet = tweet.length();
          var current_string = "";
          var lastvalue = 0;
          var length = 0;

          // padding for display text
          var padding_top = 45;
          var padding_bottom = 10;
          var padding_sides = 5;

          var x_pos = 0;
          //var y_pos = 50;
          var y_pos = 0 + padding_top;
          var max_width = dw - padding_sides;
          var y_cal = 0;
          var r = dw;
          var x1 = 0;


           // draw multi-line tweet text
           dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_TRANSPARENT);

           // here, we loop thru each character
           for (var l=0; l <= length_of_tweet; l++) {

              // are we rendering text in a circle?
              if (canvas_circ) {

                  y_cal = y_pos + (font_height/2);

                // if so, calculate max_width based on position across a circle

                 if (y_pos > (r/2)) {
                   x1 = r - (-y_cal+r);
                 } else {
                   x1 = r - (y_cal);
                 }

                 // remember pythagoras theorem?
                 max_width = (Math.sqrt((r*r) - (x1*x1))) - padding_sides;

              }

              // let's grab the current section of text + next character, and it's calc it's length
              current_string = tweet.substring(lastvalue, l);
              length = dc.getTextWidthInPixels(current_string, font);

              if ( (y_pos+font_height) < (dh - padding_bottom) ) {

                  // have we reached a space, and near the end of the line? then truncate...
                  if ( (l>1) && (tweet.substring(l-1,l).equals(" ")) && (length > (max_width*5/6)) ) {

                     dc.drawText(dw/2,y_pos,font, current_string ,Gfx.TEXT_JUSTIFY_CENTER);
                     y_pos = y_pos + font_height;
                     lastvalue = l;

                  // otherwise, have we exceeded the length?
                  } else if (length > max_width) {

                     dc.drawText(dw/2,y_pos,font, current_string ,Gfx.TEXT_JUSTIFY_CENTER);
                     y_pos = y_pos + font_height;
                     lastvalue = l;

                  // if not, are we at the last section?
                  } else if (l == length_of_tweet) {

                     dc.drawText(dw/2,y_pos,font, current_string ,Gfx.TEXT_JUSTIFY_CENTER);
                     y_pos = y_pos + font_height;
                     lastvalue = l;

                  }


              }

         }

         if (debug) {
            Sys.println(Lang.format("current_tweet: $1$", [current_tweet]));
         }


      } else {

        // do we have bluetooth? ok, then we're loading stuff
        if (bluetooth) {
        dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_TRANSPARENT);
        dc.drawBitmap((dw-gciqlogo.getWidth())/2, (dh-gciqlogo.getHeight())/2, gciqlogo);

        } else {
        dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_TRANSPARENT);
          dc.drawText(dw/2,(dh/2)-(dc.getFontHeight(Gfx.FONT_SYSTEM_SMALL)/2),Gfx.FONT_SYSTEM_SMALL,"Disconnected",Gfx.TEXT_JUSTIFY_CENTER);
        }

        // nope, we don't have tweets yet
        dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);

        // let's draw a rotating arc to show we're loading stuff ..
        dc.setPenWidth(3);
        degreeStart = degreeStart%360;
        dc.drawArc(dw/2, dh/2, dw*3/7, Gfx.ARC_COUNTER_CLOCKWISE, degreeStart, degreeStart+24);
        degreeStart = degreeStart - 6;

      }

      // we got_tweets? then increment the next tweet to display
      if (got_tweets != null) {
        current_tweet++;
      }

      // have we sent a request yet? nope, then generate the callback
      if (sent_request == null) {
          main_callback();
      }

    }

    //! Called when this View is removed from the screen. Save the
    //! state of this View here. This includes freeing resources from
    //! memory.
    function onHide() {
    }

    // this is our animation loop callback
    function main_callback() {

      if (got_tweets == null && sent_request == null) {
        getTweets();
        sent_request = true;
      }

      // redraw the screen
      Ui.requestUpdate();


      delay = (got_tweets == null) ? timer_fast : timer_steps;

      if (timer1) {
        timer1.stop();
      }

      timer1 = new Timer.Timer();
      timer1.start(method(:main_callback), delay, false );


    }


    // here's where we grab the tweets via a network request
    function getTweets() {

      var params = {};

      var headers = {
        "Content-Type" => Comm.REQUEST_CONTENT_TYPE_JSON
      };

      var options = {
        :method => Comm.HTTP_REQUEST_METHOD_GET,
        :headers => headers,
        :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
      };

      // this url proxies the tweets for #ciqsummit2017
      // using the real twitter API will mean we will quickly run out of API requests
      var url = "";
      var random = Math.rand();
      url = "https://s3.us-east-2.amazonaws.com/ciqsummit2017/tweets?"+random.toString();

      if (Comm has :makeWebRequest ) {
        Comm.makeWebRequest(
          url, params, options, method(:onReceiveTweetData)
        );

      } else {
        Comm.makeJsonRequest(
          url, params, options, method(:onReceiveTweetData)
        );
      }
    }


    //! The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {

    }

    //! Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {

      // bye bye timer
      if (timer1) {
        timer1.stop();
      }

      timer_steps = timer_timeout;

    }

}
