library(gems)
data("SimpleHill")

dims <- as.list(SimpleHill[1, c("sf", "ori")])
grt::gaborPatch(sf = dims$sf, theta = dims$ori, grating = "sin")
