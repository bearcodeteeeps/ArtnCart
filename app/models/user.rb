class User < ApplicationRecord
  before_create :increment_premium

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :orders
  has_many :products, through: :orders
  include SimpleDiscussion::ForumUser



  def name
    if Thread.current[:user]
    Thread.current[:user].email
    end
  end

  def current_user_cart
    "cart#{id}"
  end

  def add_to_cart(product_id)
    $redis.hincrby current_user_cart, product_id, 1
  end

  def remove_from_cart(product_id)
    $redis.hdel current_user_cart, product_id
  end

  def remove_one_from_cart(product_id)
    $redis.hincrby current_user_cart, product_id, -1
  end

  def cart_count
    quantities = $redis.hvals "cart#{id}"
    quantities.reduce(0) {|sum, qty| sum + qty.to_i}
  end

  def cart_total_price
    get_cart_products_with_qty.map { |product, qty| product.price * qty.to_i}.reduce(:+)
  end

  def get_cart_products_with_qty
    cart_ids = []
    cart_qtys = []
    ($redis.hgetall current_user_cart).map do |key, value|
      cart_ids << key
      cart_qtys << value
    end
    cart_products = Product.find(cart_ids)
    cart_products.zip(cart_qtys)
  end

  def purchase_cart_products!
    get_cart_products_with_qty.each do |product, qty|
      self.orders.create(user: self, product: product, quantity: qty)
    end
    $redis.del current_user_cart
  end

  def increment_premium
    if premium_until.nil? || (premium_until < Date.today)
      self.premium_until = Date.today
    end
    self.premium_until += 1.month
  end

end
