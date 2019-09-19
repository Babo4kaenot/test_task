require 'time'

class Transactions
  def initialize(date, description, amount)
    day = date.split(" ").first
    day = day.size == 1 ? "0" + day : day
    date[0] = day 

    @date        = Time.parse date
    @description = description
    @amount      = amount
  end
  
  def to_hash
    {
      date:         @date,
      description:  @description,
      amount:       @amount
    }
  end
end
