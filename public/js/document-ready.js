$(document).ready( function() {

          $( "#form" )
        . validate(
          {
              rules
              : {
                  password : "required",
                  password_again : { equalTo : "#password" }
              }
          }
        );
  } );
// ready function
