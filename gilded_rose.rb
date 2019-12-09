MAX_QUALITY = 50
MIN_QUALITY = 0

INVENTORY = {
    '+5 Dexterity Vest' => {
        sell_in_decrease_rate: 1,
        qulity_degrade_rate_before_sell_in_date: 1,
        qulity_degrade_rate_after_sell_in_date: 2,
        qulity_degrade_rate_by_sell_in_period: {},
        event: nil
    },
    'Aged Brie' => {
        sell_in_decrease_rate: 1,
        qulity_degrade_rate_before_sell_in_date: -1,
        qulity_degrade_rate_after_sell_in_date: -2,
        qulity_degrade_rate_by_sell_in_period: {},
        event: nil
    },
    'Elixir of the Mongoose' => {
        sell_in_decrease_rate: 1,
        qulity_degrade_rate_before_sell_in_date: 1,
        qulity_degrade_rate_after_sell_in_date: 2,
        qulity_degrade_rate_by_sell_in_period: {},
        event: nil
    },
    'Sulfuras, Hand of Ragnaros' => {
        sell_in_decrease_rate: 0,
        qulity_degrade_rate_before_sell_in_date: 0,
        qulity_degrade_rate_after_sell_in_date: 0,
        qulity_degrade_rate_by_sell_in_period: {},
        event: nil
    },
    'Backstage passes'  => {
        sell_in_decrease_rate: 1,
        qulity_degrade_rate_before_sell_in_date: -1,
        qulity_degrade_rate_after_sell_in_date: -1,
        qulity_degrade_rate_by_sell_in_period: {5 => -3, 10 => -2},
        event: nil
    },
    'Backstage passes to a TAFKAL80ETC concert'  => {
        sell_in_decrease_rate: 1,
        qulity_degrade_rate_before_sell_in_date: -1,
        qulity_degrade_rate_after_sell_in_date: 0,
        qulity_degrade_rate_by_sell_in_period: {},
        event: 'concert'
    },
    'Conjured Mana Cake' => {
        sell_in_decrease_rate: 1,
        qulity_degrade_rate_before_sell_in_date: 2,
        qulity_degrade_rate_after_sell_in_date: 4,
        qulity_degrade_rate_by_sell_in_period: {},
        event: nil
    }
}

QUALITY_AFTER_EVENT = {
    'Backstage passes to a TAFKAL80ETC concert' => {
        'concert' => 0
    }
}

def update_quality(items)
  items.each do |item|
    update_item(item)
  end
end

def update_item(item)
  inventory_item = INVENTORY[item.name]

  if inventory_item.nil?
    # item not in INVENTORY, process as default
    if item.sell_in > 0
      item.quality = calculate_item_quality(item.quality, 1)
    else
      item.quality = calculate_item_quality(item.quality, 2)
    end

    item.sell_in = calculate_sell_in(item.sell_in, 1)
  else
    if inventory_item[:event].nil?
      if item.sell_in > 0
        # update item before sellin
        if inventory_item[:qulity_degrade_rate_by_sell_in_period].empty?
          item.quality = calculate_item_quality(item.quality, inventory_item[:qulity_degrade_rate_before_sell_in_date])
        else
          # update item within sellin period
          qulity_degrade_rate_by_sell_in_period = inventory_item[:qulity_degrade_rate_by_sell_in_period].sort.to_h
          if item.sell_in <= qulity_degrade_rate_by_sell_in_period.sort.to_h.keys.last
            qulity_degrade_rate_by_sell_in_period.each do |k, v|
              if item.sell_in <= k
                item.quality = calculate_item_quality(item.quality, v)
                break
              end
            end
          else
            # update item before any sellin period
            item.quality = calculate_item_quality(item.quality, inventory_item[:qulity_degrade_rate_before_sell_in_date])
          end
        end
      else
        # update item after sellin
        item.quality = calculate_item_quality(item.quality, inventory_item[:qulity_degrade_rate_after_sell_in_date])
      end
    else
      # update item after event
      item.quality = calculate_item_quality(item.quality, inventory_item[:qulity_degrade_rate_after_sell_in_date], QUALITY_AFTER_EVENT[item.name][INVENTORY[item.name][:event]])
    end

    item.sell_in = calculate_sell_in(item.sell_in, inventory_item[:sell_in_decrease_rate])
  end
end

def calculate_item_quality(item_quality, item_quality_degrade_rate, after_event_quality=nil)
  if after_event_quality.nil?
    [[item_quality - item_quality_degrade_rate, MIN_QUALITY].max, MAX_QUALITY].min
  else
    after_event_quality
  end
end

def calculate_sell_in(sell_in, sell_in_decrease_rate)
  sell_in - sell_in_decrease_rate
end

# DO NOT CHANGE THINGS BELOW -----------------------------------------

Item = Struct.new(:name, :sell_in, :quality)

# We use the setup in the spec rather than the following for testing.
#
# Items = [
#   Item.new("+5 Dexterity Vest", 10, 20),
#   Item.new("Aged Brie", 2, 0),
#   Item.new("Elixir of the Mongoose", 5, 7),
#   Item.new("Sulfuras, Hand of Ragnaros", 0, 80),
#   Item.new("Backstage passes to a TAFKAL80ETC concert", 15, 20),
#   Item.new("Conjured Mana Cake", 3, 6),
# ]

