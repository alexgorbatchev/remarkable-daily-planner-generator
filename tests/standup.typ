#import "../src/config.typ" as config
#import "../src/views/daily-standup.typ": daily-standup
#import "helpers.typ": descendants, plain
#import "presets.typ": STANDUP_TITLED

#for settings in (config.STANDUP, STANDUP_TITLED, (..STANDUP_TITLED, title_show: false)) {
  for header in (config.header, (..config.header, height: 20mm)) {
    let page = daily-standup(2026, 9, 30, settings: settings, header: header)
    let bodies = descendants(page, block).filter(it => it.at("height", default: auto) != auto)
    assert.eq(bodies.len(), 1)
    assert.eq(bodies.first().height, config.page.height - 2 * config.page.margin_y - header.height)
    assert.eq(plain(bodies.first().body), if settings.title_show { settings.title } else { "" })
  }
}

Standup assertions passed.
