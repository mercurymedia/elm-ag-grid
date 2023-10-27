module Components.Components exposing (viewPage)

import Css
import Html.Styled exposing (Html, a, div, span, text)
import Html.Styled.Attributes exposing (css, href, target)


viewPage : { headline : String, pageUrl : String } -> List (Html msg) -> Html msg
viewPage { headline, pageUrl } content =
    div [ css [ Css.width (Css.pct 100), Css.margin2 (Css.rem 0) (Css.rem 1) ] ]
        (div [ css [ Css.margin2 (Css.rem 1) (Css.px 0), Css.displayFlex, Css.alignItems Css.center ] ]
            [ span [ css [ Css.fontSize (Css.rem 1.8), Css.marginRight (Css.px 5) ] ] [ text headline ]
            , a [ href pageUrl, target "_blank" ] [ text "[source]" ]
            ]
            :: content
        )
