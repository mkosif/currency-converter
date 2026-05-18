let storage: LocalStorage = new LocalStorage();

@Entry(storage)
@Component
struct WidgetCard {
  @LocalStorageProp('pair') pair: string = 'USD → EUR';
  @LocalStorageProp('rate') rate: string = '—';
  @LocalStorageProp('lastUpdated') lastUpdated: string = '—';

  build() {
    Column({ space: 4 }) {
      Text(this.pair)
        .fontSize(11)
        .fontColor(Color.White)
        .opacity(0.85)

      Text(this.rate)
        .fontSize(22)
        .fontWeight(700)
        .fontColor(Color.White)

      Text(this.lastUpdated)
        .fontSize(9)
        .fontColor(Color.White)
        .opacity(0.7)
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .backgroundColor('#2050E0')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      postCardAction(this, {
        action: 'message',
        abilityName: 'EntryFormAbility',
        params: {
          msg: 'refresh'
        }
      });
    })
  }
}
