const mongoose = require('mongoose');

const scheduleSchema = new mongoose.Schema({
  user:      { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  subject:   { type: mongoose.Schema.Types.ObjectId, ref: 'Subject', required: true },
  title:     { type: String, required: true, trim: true },
  date:      { type: Date, required: true },
  startTime: { type: String, required: true },
  endTime:   { type: String, required: true },
  notes:     { type: String, default: '' },
  completed: { type: Boolean, default: false },
}, { timestamps: true });

module.exports = mongoose.model('Schedule', scheduleSchema);
