import Testing

@Suite struct RemoveInvisiblesTests {
    @Test func removesZeroWidthAndFormattingScalars() {
        #expect(removeInvisibles("a\u{200B}b\u{2060}c\u{FEFF}d\u{00AD}e") == "abcde")
    }

    @Test func removesBidiMarks() {
        #expect(removeInvisibles("\u{200E}left\u{200F} \u{202A}x\u{202C} \u{2066}y\u{2069}") == "left x y")
    }

    @Test func turnsNonBreakingSpacesIntoSpaces() {
        #expect(removeInvisibles("10\u{00A0}kg\u{202F}net\u{2007}1") == "10 kg net 1")
    }

    @Test func keepsNormalWhitespaceAndNewlines() {
        #expect(removeInvisibles("a b\tc\nd\r\ne") == "a b\tc\nd\r\ne")
    }

    @Test func keepsEmojiJoinSequences() {
        let family = "👨\u{200D}👩\u{200D}👧"
        let heartOnFire = "❤\u{FE0F}\u{200D}🔥"
        let skinTone = "👩🏽\u{200D}💻"
        let textStyle = "☺\u{FE0E}"
        #expect(removeInvisibles(family) == family)
        #expect(removeInvisibles(textStyle) == textStyle)
        #expect(removeInvisibles(heartOnFire) == heartOnFire)
        #expect(removeInvisibles(skinTone) == skinTone)
    }

    @Test func keepsNonJoinerUsedByPersian() {
        #expect(removeInvisibles("می\u{200C}خواهم") == "می\u{200C}خواهم")
    }

    @Test func leavesEmptyStringEmpty() {
        #expect(removeInvisibles("") == "")
    }
}

@Suite struct TrimWhitespaceTests {
    @Test func trimsBothEnds() {
        #expect(trimWhitespace("  \n\thello world \n") == "hello world")
    }

    @Test func keepsInnerWhitespace() {
        #expect(trimWhitespace("a  b\nc") == "a  b\nc")
    }

    @Test func whitespaceOnlyBecomesEmpty() {
        #expect(trimWhitespace(" \n ") == "")
    }
}

@Suite struct StraightenQuotesTests {
    @Test func straightensDoubleQuotes() {
        #expect(straightenQuotes("\u{201C}hi\u{201D} \u{201E}lo\u{201F}") == "\"hi\" \"lo\"")
    }

    @Test func straightensSingleQuotesAndApostrophes() {
        #expect(straightenQuotes("\u{2018}it\u{2019}s\u{201A}\u{201B}") == "'it's''")
    }

    @Test func leavesOtherCharactersAlone() {
        #expect(straightenQuotes("«guillemets» and 5′ 3″") == "«guillemets» and 5′ 3″")
    }
}

@Suite struct RemoveTrackingParametersTests {
    @Test func removesUtmParameters() {
        #expect(removeTrackingParameters("https://example.com/a?utm_source=x&utm_medium=y&id=3") == "https://example.com/a?id=3")
    }

    @Test func removesAllKnownTrackers() {
        let url = "https://example.com/?fbclid=1&gclid=2&dclid=3&gbraid=4&wbraid=5&msclkid=6&mc_cid=7&mc_eid=8&igshid=9&yclid=10&_hsenc=11&_hsmi=12&mkt_tok=13&ref_src=14"
        #expect(removeTrackingParameters(url) == "https://example.com/")
    }

    @Test func matchesParameterNamesCaseInsensitively() {
        #expect(removeTrackingParameters("https://example.com/?UTM_Source=x&FBCLID=y") == "https://example.com/")
    }

    @Test func removesSiOnlyForYouTubeAndSpotify() {
        #expect(removeTrackingParameters("https://youtu.be/abc?si=xyz") == "https://youtu.be/abc")
        #expect(removeTrackingParameters("https://www.youtube.com/watch?v=abc&si=xyz") == "https://www.youtube.com/watch?v=abc")
        #expect(removeTrackingParameters("https://open.spotify.com/track/1?si=xyz") == "https://open.spotify.com/track/1")
        #expect(removeTrackingParameters("https://example.com/?si=xyz") == "https://example.com/?si=xyz")
    }

    @Test func stripsTextFragmentDirective() {
        #expect(removeTrackingParameters("https://example.com/page#:~:text=hello%20world") == "https://example.com/page")
        #expect(removeTrackingParameters("https://example.com/page#intro:~:text=hello") == "https://example.com/page#intro")
    }

    @Test func keepsOrdinaryFragment() {
        #expect(removeTrackingParameters("https://example.com/page?utm_source=x#intro") == "https://example.com/page#intro")
    }

    @Test func returnsInputUnchangedWhenNothingToStrip() {
        let url = "https://example.com/search?q=a%20b&tag=c+d"
        #expect(removeTrackingParameters(url) == url)
    }

    @Test func keepsPercentEncodingOfRemainingParameters() {
        #expect(removeTrackingParameters("https://example.com/?q=a%26b&utm_source=x") == "https://example.com/?q=a%26b")
    }

    @Test func trimsSurroundingWhitespaceOfAUrl() {
        #expect(removeTrackingParameters("  https://example.com/?gclid=1\n") == "https://example.com/")
    }

    @Test func ignoresTextContainingAUrl() {
        let text = "see https://example.com/?utm_source=x"
        #expect(removeTrackingParameters(text) == text)
    }

    @Test func ignoresNonHttpSchemes() {
        let text = "ftp://example.com/?utm_source=x"
        #expect(removeTrackingParameters(text) == text)
    }

    @Test func ignoresPlainWords() {
        #expect(removeTrackingParameters("hello") == "hello")
    }
}

@Suite struct StripMailtoTests {
    @Test func stripsScheme() {
        #expect(stripMailto("mailto:anna@example.com") == "anna@example.com")
    }

    @Test func dropsQuery() {
        #expect(stripMailto("mailto:anna@example.com?subject=Hi&body=Yo") == "anna@example.com")
    }

    @Test func isCaseInsensitiveAndTrims() {
        #expect(stripMailto("  MAILTO:anna@example.com\n") == "anna@example.com")
    }

    @Test func decodesPercentEncoding() {
        #expect(stripMailto("mailto:anna%2Bnews@example.com") == "anna+news@example.com")
    }

    @Test func ignoresTextThatIsNotOnlyAMailtoUrl() {
        #expect(stripMailto("write mailto:anna@example.com") == "write mailto:anna@example.com")
        #expect(stripMailto("mailto:anna@example.com and more") == "mailto:anna@example.com and more")
        #expect(stripMailto("mailto:") == "mailto:")
    }
}

@Suite struct StripTelTests {
    @Test func stripsScheme() {
        #expect(stripTel("tel:+46701234567") == "+46701234567")
    }

    @Test func isCaseInsensitiveAndDecodes() {
        #expect(stripTel(" TEL:+46-70-123%2045 ") == "+46-70-123 45")
    }

    @Test func ignoresTextThatIsNotOnlyATelUrl() {
        #expect(stripTel("call tel:123") == "call tel:123")
        #expect(stripTel("tel:") == "tel:")
        #expect(stripTel("telephone") == "telephone")
    }
}

@Suite struct CleanTests {
    @Test func appliesEnabledTransformsInOrder() {
        #expect(clean(" \u{200B}https://example.com/?utm_source=x \n", options: TransformOptions()) == "https://example.com/")
    }

    @Test func defaultsLeaveQuotesAlone() {
        #expect(clean("\u{201C}hi\u{201D}", options: TransformOptions()) == "\u{201C}hi\u{201D}")
    }

    @Test func skipsDisabledTransforms() {
        let options = TransformOptions(
            removeInvisibles: false, trimWhitespace: false, straightenQuotes: false,
            removeTrackingParameters: false, stripMailto: false, stripTel: false
        )
        let text = " a\u{200B} mailto:x "
        #expect(clean(text, options: options) == text)
    }

    @Test func invisiblesRemovedBeforeMailtoCheck() {
        #expect(clean("mailto:anna@example.com\u{200B}", options: TransformOptions()) == "anna@example.com")
    }
}
