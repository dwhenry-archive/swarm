describe 'passing specs' do
  it 'squared numbers' do
    (1..1_000_000).each do |i|
      (i * i * i).should == (i * i * i)
    end
  end

  it 'sqrt is less than half' do
    (5..1_000_000).each do |i|
      (i ** 0.5).should < (i * 0.5)
    end
  end
end