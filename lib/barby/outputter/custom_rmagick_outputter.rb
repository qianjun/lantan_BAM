require 'rubygems'
require 'barby'
require 'barby/outputter/rmagick_outputter'

module Barby
  class CustomRmagickOutputter < RmagickOutputter
    register :to_image_with_data
    def to_image_with_data(*a)
      #Make canvas  bigger
      canvas = Magick::ImageList.new
      canvas.new_image(590, 326)
      #canvas.new_image(full_width , full_height + 10)
      canvas << to_image(*a)
      canvas = canvas.flatten_images
      #Make the text
      text = Magick::Draw.new
      text.font_family = 'helvetica'
      #text.pointsize = 14
      text.pointsize = 48
      text.gravity = Magick::SouthGravity
      text.annotate(canvas , 0,0,0,0, barcode.data.to_s+barcode.checksum.to_s)
      canvas
    end
  end
end