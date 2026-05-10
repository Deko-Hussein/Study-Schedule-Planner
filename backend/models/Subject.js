const mongoose = require('mongoose');

const subjectSchema = new mongoose.Schema({
  user:        { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name:        { type: String, required: true, trim: true },
  color:       { type: String, default: '#4F46E5' },
  creditHours: { type: Number, default: 3 },
  icon:        { type: String, default: 'book' },
}, { timestamps: true });

module.exports = mongoose.model('Subject', subjectSchema);
