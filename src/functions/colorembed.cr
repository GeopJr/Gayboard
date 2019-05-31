# This function calculates the color and it's opacity based on the min_reactions set, current reactions and the previous color used
class ColorEmbed
  def initialize(colorIndex : UInt32 | Int32, min_reactions : UInt32 | Int32, current_reactions : UInt32 | Int32)
    hexBeforeCheck = [] of String
    @hexAfterCheck = [] of String
    # All the rainbow colors in rgb
    colorsRainbow = ["231,0,0", "255,140,0", "255,239,0", "0,129,31", "0,68,255", "118,0,137"]
    # If current reactions are more or equal to double the min_reactions, use full opacity
    if current_reactions >= (min_reactions + min_reactions)
      # RGB to hex
      hexColorRed = colorsRainbow[colorIndex].split(",")[0].to_i.to_s(16)
      hexColorGreen = colorsRainbow[colorIndex].split(",")[1].to_i.to_s(16)
      hexColorBlue = colorsRainbow[colorIndex].split(",")[2].to_i.to_s(16)
    else
      # Calculate min_react % current reactions and remove it from 100
      minusPercent = 100 - (min_reactions.to_f / current_reactions.to_f * 100).to_i
      # Don't want it too dark so if its below 10% keep it at 10
      if minusPercent < 10
        minusPercentVisible = 10
      else
        minusPercentVisible = minusPercent
      end
      decreasedColors = [] of Int32
      # Calculate the above calculated precentage % original colors
      colorsRainbow[colorIndex].split(",").each do |color|
        decreasedColors << ((minusPercentVisible.to_f / 100.0) * color.to_f).to_i
      end
      # To hex
      hexColorRed = decreasedColors[0].to_s(16)
      hexColorGreen = decreasedColors[1].to_s(16)
      hexColorBlue = decreasedColors[2].to_s(16)
    end
    hexBeforeCheck << hexColorRed
    hexBeforeCheck << hexColorGreen
    hexBeforeCheck << hexColorBlue
    # Check if each color has less that 2 characters and add a 0 if they do
    hexBeforeCheck.each do |color|
      if color.size < 2
        checkedColor = "0#{color}"
      else
        checkedColor = color
      end
      @hexAfterCheck << checkedColor
    end
  end

  # Return it
  def color
    hexColor = @hexAfterCheck.join("")
  end
end
