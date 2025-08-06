var Clicked = false
var Selected_Map = null
var First = false

document.addEventListener('DOMContentLoaded', function () {
    window.addEventListener("message", (event) => {
      //-------------------------------//
        if (event.data.type === "OpenMenu") {
          $('body').css('display', 'flex');
          $('#Wind').text(parseFloat(event.data.Server_Data.WindSpeed.toFixed(1))+" m/s");
          $('#Weather').text(event.data.Server_Data.Weather);
          $('#Temparature').text(event.data.Server_Data.Temperature);
          $('#Time').text(event.data.Server_Data.Time);
          $('#Day').text(event.data.Server_Data.Day);
          $('.titleText').text(event.data.Texts.Server_Name);
          $('.titleSubText').text(event.data.Texts.Roleplay);
          $('.lastButton').text(event.data.Texts.Last_Location);
          $('#WeatherHead').text(event.data.Texts.Weather);
          $('#WindHead').text(event.data.Texts.Wind_Speed);
          $('#TemparatureHead').text(event.data.Texts.Temparature);
          if (First === false) {
            $(".mapSide").html(`
            <div class="mapBox">
            <div class="mapBoxLine"></div>
            <div class="map" id="map"></div>
          </div>
          `)
            createMap()
            First = true 
        //-------------------------------//
        event.data.Spawns.forEach(Spawn => {
          $(".mapSide").append(`
            <div class="mapInfosSide loc${Spawn.Spawn_ID}">
            <div class="mapTextSide" id="Map_Info_${Spawn.Spawn_ID}">
              <img src="${Spawn.Banner}" alt="" class="mapTextBgImg" />
              <div class="mapTextLine"></div>
              <div class="mapTextBox">
                <div class="mapTextTitleBox">${Spawn.Label}</div>
                <div class="mapTextInfoBox">
                  <div class="mapTextInfoBoxTitleSide">
                    <div class="mapTextInfoBoxTitle">Contents</div>
                    <div class="mapTextInfoBoxTitleLine"></div>
                  </div>
                  <p class="mapTextInfoBoxSubTitle">
                    ${Spawn.Description}
                  </p>
                </div>
              </div>
              <svg
                viewBox="0 0 200 331"
                fill="none"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  fill-rule="evenodd"
                  clip-rule="evenodd"
                  d="M200 10C200 4.47715 195.523 0 190 0H10C4.47715 0 0 4.47716 0 10V319.825C0 328.868 11.4515 333.632 18.6411 328.146C26.2139 322.369 34.2299 317.395 42.5975 313.299C60.7964 304.391 80.3018 299.806 100 299.806C119.698 299.806 139.204 304.391 157.403 313.299C165.77 317.395 173.786 322.369 181.359 328.146C188.548 333.632 200 328.868 200 319.825V10Z"
                  fill="black"
                  fill-opacity="0.25"
                />
                <g filter="url(#filter0_d_13_3763)">
                  <mask
                    id="path-2-outside-1_13_3763"
                    maskUnits="userSpaceOnUse"
                    x="12"
                    y="12"
                    width="176"
                    height="295"
                    fill="black"
                  >
                    <rect fill="white" x="12" y="12" width="176" height="295" />
                    <path
                      fill-rule="evenodd"
                      clip-rule="evenodd"
                      d="M185.429 24C185.429 18.4772 180.951 14 175.429 14H24C18.4772 14 14 18.4771 14 24V293.975C14 303.019 25.5204 307.841 32.8615 302.56C38.4932 298.509 44.393 294.966 50.5122 291.971C66.1112 284.335 82.8301 280.405 99.7143 280.405C116.599 280.405 133.317 284.335 148.916 291.971C155.036 294.966 160.935 298.509 166.567 302.56C173.908 307.841 185.429 303.019 185.429 293.975V24Z"
                    />
                  </mask>
                  <path
                    fill-rule="evenodd"
                    clip-rule="evenodd"
                    d="M185.429 24C185.429 18.4772 180.951 14 175.429 14H24C18.4772 14 14 18.4771 14 24V293.975C14 303.019 25.5204 307.841 32.8615 302.56C38.4932 298.509 44.393 294.966 50.5122 291.971C66.1112 284.335 82.8301 280.405 99.7143 280.405C116.599 280.405 133.317 284.335 148.916 291.971C155.036 294.966 160.935 298.509 166.567 302.56C173.908 307.841 185.429 303.019 185.429 293.975V24Z"
                    fill="#0C0C0C"
                  />
                  <path
                    d="M50.5122 291.971L51.3915 293.767L51.3915 293.767L50.5122 291.971ZM148.916 291.971L149.796 290.175L149.796 290.175L148.916 291.971ZM32.8615 302.56L31.6936 300.937L32.8615 302.56ZM166.567 302.56L167.735 300.937L166.567 302.56ZM24 16H175.429V12H24V16ZM16 293.975V24H12V293.975H16ZM34.0295 304.184C39.5722 300.196 45.3757 296.712 51.3915 293.767L49.6329 290.175C43.4103 293.221 37.4141 296.821 31.6936 300.937L34.0295 304.184ZM51.3915 293.767C66.7248 286.262 83.1438 282.405 99.7143 282.405V278.405C82.5164 278.405 65.4975 282.409 49.6328 290.175L51.3915 293.767ZM99.7143 282.405C116.285 282.405 132.704 286.262 148.037 293.767L149.796 290.175C133.931 282.409 116.912 278.405 99.7143 278.405V282.405ZM148.037 293.767C154.053 296.712 159.856 300.196 165.399 304.184L167.735 300.937C162.015 296.821 156.018 293.221 149.796 290.175L148.037 293.767ZM183.429 24V293.975H187.429V24H183.429ZM12 293.975C12 299.447 15.504 303.542 19.8704 305.469C24.2198 307.388 29.7025 307.297 34.0295 304.184L31.6936 300.937C28.6795 303.105 24.7314 303.242 21.4853 301.81C18.2562 300.385 16 297.547 16 293.975H12ZM165.399 304.184C169.726 307.297 175.209 307.389 179.558 305.469C183.925 303.542 187.429 299.447 187.429 293.975H183.429C183.429 297.547 181.172 300.385 177.943 301.81C174.697 303.242 170.749 303.105 167.735 300.937L165.399 304.184ZM175.429 16C179.847 16 183.429 19.5817 183.429 24H187.429C187.429 17.3726 182.056 12 175.429 12V16ZM24 12C17.3726 12 12 17.3726 12 24H16C16 19.5817 19.5817 16 24 16V12Z"
                    fill="#B2C7FA"
                    mask="url(#path-2-outside-1_13_3763)"
                  />
                </g>
                <defs>
                  <filter
                    id="filter0_d_13_3763"
                    x="9"
                    y="9"
                    width="181.429"
                    height="300.749"
                    filterUnits="userSpaceOnUse"
                    color-interpolation-filters="sRGB"
                  >
                    <feFlood flood-opacity="0" result="BackgroundImageFix" />
                    <feColorMatrix
                      in="SourceAlpha"
                      type="matrix"
                      values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0"
                      result="hardAlpha"
                    />
                    <feOffset />
                    <feGaussianBlur stdDeviation="1.5" />
                    <feComposite in2="hardAlpha" operator="out" />
                    <feColorMatrix
                      type="matrix"
                      values="0 0 0 0 0.698039 0 0 0 0 0.780392 0 0 0 0 0.980392 0 0 0 0.2 0"
                    />
                    <feBlend
                      mode="normal"
                      in2="BackgroundImageFix"
                      result="effect1_dropShadow_13_3763"
                    />
                    <feBlend
                      mode="normal"
                      in="SourceGraphic"
                      in2="effect1_dropShadow_13_3763"
                      result="shape"
                    />
                  </filter>
                </defs>
              </svg>
            </div>
            <div class="mapInfo" id="Map_Button_${Spawn.Spawn_ID}">
          <svg id ="MapEffect_${Spawn.Spawn_ID}" width="135" height="150" viewBox="0 0 135 150" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M55.7006 4.19315C62.9895 -0.0643818 72.0105 -0.0643818 79.2998 4.19315L122.426 29.3842C129.594 33.5713 134 41.2431 134 49.5375V100.462C134 108.757 129.594 116.428 122.426 120.616L79.2998 145.807C72.0105 150.064 62.9895 150.064 55.7006 145.807L12.5742 120.616C5.40594 116.428 1 108.757 1 100.462V49.5375C1 41.2431 5.40594 33.5713 12.5742 29.3842L55.7006 4.19315Z" stroke="#B2C7FA" stroke-width="2"/>
          </svg>

              <img id="Map_Img_${Spawn.Spawn_ID}" src= "${Spawn.Image}" alt="" class="mapImg" />
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 150 150"
                fill="none"
              >
                <path
                  d="M62.5 7.21688C70.235 2.75106 79.765 2.75106 87.5 7.21688L127.452 30.2831C135.187 34.7489 139.952 43.0021 139.952 51.9338V98.0662C139.952 106.998 135.187 115.251 127.452 119.717L87.5 142.783C79.765 147.249 70.235 147.249 62.5 142.783L22.5481 119.717C14.8131 115.251 10.0481 106.998 10.0481 98.0662V51.9338C10.0481 43.0021 14.8131 34.7489 22.5481 30.2831L62.5 7.21688Z"
                  fill="black"
                  fill-opacity="0.25"
                />
                <path
                  d="M87 13.0829L122.622 33.6491C130.047 37.9363 134.622 45.8594 134.622 54.4338V95.5662C134.622 104.141 130.047 112.064 122.622 116.351L87 136.917C79.5744 141.204 70.4256 141.204 63 136.917L27.3782 116.351C19.9526 112.064 15.3782 104.141 15.3782 95.5662V54.4338C15.3782 45.8594 19.9526 37.9363 27.3782 33.6491L63 13.0829C70.4256 8.79572 79.5744 8.79572 87 13.0829Z"
                  stroke="#B2C7FA"
                  stroke-width="2"
                />
              </svg>
            </div>
          </div>
        `)
        //-------------------------------//
        $("#Map_Button_" + Spawn.Spawn_ID).click(function () {
                if (Clicked === false) {
                    Clicked = true
                    $("#Map_Button_" + Spawn.Spawn_ID+":active").css('scale', '1.5');
                    goToCoords(Spawn.Spawn_Coords.x, Spawn.Spawn_Coords.y)
                    $("#Map_Img_1").attr("src","./img/1_icon.png");
                    $("#Map_Img_2").attr("src","./img/2_icon.png");
                    $("#Map_Img_3").attr("src","./img/3_icon.png");
                    $("#Map_Img_4").attr("src","./img/4_icon.png");
                    $("#Map_Img_5").attr("src","./img/5_icon.png");
                    $("#Map_Img_" + Spawn.Spawn_ID).attr("src","./img/clickandspawn.png");
                    $(".mapTextSide").css('opacity', '0');
                    $("#MapEffect_1").css('opacity', '0');
                    $("#MapEffect_2").css('opacity', '0');
                    $("#MapEffect_3").css('opacity', '0');
                    $("#MapEffect_4").css('opacity', '0');
                    $("#MapEffect_5").css('opacity', '0');
                    $(".mapImg").css('filter', 'drop-shadow(5px 5px 15px #8a9acc54)');
                    $("#Map_Img_" + Spawn.Spawn_ID).css('filter', 'drop-shadow(5px 5px 25px #8a9accac)');
                    $("#MapEffect_" + Spawn.Spawn_ID).css('opacity', '1');
                    $("#Map_Info_" + Spawn.Spawn_ID).css('opacity', '1');
                    if (Selected_Map == Spawn.Spawn_ID) {
                      $.post(`https://${GetParentResourceName()}/SpawnLocation`, JSON.stringify({
                        Location: Number(Selected_Map),
                      }));
                    }
                    if (Selected_Map !== Spawn.Spawn_ID) {
                      Selected_Map = Spawn.Spawn_ID
                      $.post(`https://${GetParentResourceName()}/NewLocation`, JSON.stringify({
                        Selected: Number(Selected_Map),
                      }));
                    }
                    setTimeout(function () {
                        Clicked = false
                    }, 250)
                }
            })
        });
      }
        //-------------------------------//
        Selected_Map = 1
        $("#Map_Img_1").attr("src","./img/clickandspawn.png");
        $("#Map_Img_1").css('filter', 'drop-shadow(5px 5px 25px #8a9accac)');
        $("#MapEffect_1").css('opacity', '1');
        $("#Map_Info_1").css('opacity', '1');
        //-------------------------------//
        setTimeout(function () {
          goToCoords(event.data.Spawns[0].Spawn_Coords.x, event.data.Spawns[0].Spawn_Coords.y)
          $("body").css('opacity', '1');
        }, 600)
        //-------------------------------//
      } else if (event.data.type === "CloseMenu") {
        $("body").css('opacity', '0');
        Selected_Map = null
        Clicked = false
        setTimeout(function () {
          $("#Map_Img_1").attr("src","./img/1_icon.png");
          $("#Map_Img_2").attr("src","./img/2_icon.png");
          $("#Map_Img_3").attr("src","./img/3_icon.png");
          $("#Map_Img_4").attr("src","./img/4_icon.png");
          $("#Map_Img_5").attr("src","./img/5_icon.png");
          $(".mapTextSide").css('opacity', '0');
          $("#MapEffect_1").css('opacity', '0');
          $("#MapEffect_2").css('opacity', '0');
          $("#MapEffect_3").css('opacity', '0');
          $("#MapEffect_4").css('opacity', '0');
          $("#MapEffect_5").css('opacity', '0');
        }, 1000)
      } else if (event.data.type === "Loading") {
        $("#Map_Img_" + event.data.location).attr("src","./img/loading.gif");
      }
      $(".lastButton").click(function () {
        if (Clicked === false) {
            Clicked = true
            $.post(`https://${GetParentResourceName()}/SpawnLastLocation`);
            setTimeout(function () {
              Clicked = false
          }, 250)
        }
      })
    });
})