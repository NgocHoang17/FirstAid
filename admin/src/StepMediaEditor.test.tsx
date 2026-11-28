import { useState } from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { expect, it, vi } from 'vitest';
import { AdminApi } from './api';
import { StepMediaEditor } from './StepMediaEditor';
import type { Step } from './models';

it('uploads files, preserves their order and descriptions, selects a layout and removes an image', async () => {
  const api = new AdminApi();
  let id = 0;
  const upload = vi.spyOn(api, 'uploadImage').mockImplementation(async () => ({id: String(++id), url: `/api/v1/media/${id}`}));
  function Editor() {
    const [step, change] = useState({images: [], image_layout:'stacked'} as unknown as Step);
    return <StepMediaEditor step={step} api={api} change={change}/>;
  }
  render(<Editor/>);
  const user = userEvent.setup();
  await user.upload(screen.getByLabelText('Tải ảnh hướng dẫn'), [new File(['one'],'one.png',{type:'image/png'}),new File(['two'],'two.png',{type:'image/png'})]);
  await waitFor(() => expect(upload).toHaveBeenCalledTimes(2));
  await user.type(await screen.findByLabelText('Mô tả ảnh 1'), 'Hình thứ nhất');
  await user.type(screen.getByLabelText('Mô tả ảnh 2'), 'Hình thứ hai');
  await user.selectOptions(screen.getByLabelText('Bố cục ảnh'), 'grid');
  await user.click(screen.getAllByRole('button',{name:'Xuống'})[0]);
  expect(screen.getByLabelText('Mô tả ảnh 1')).toHaveValue('Hình thứ hai');
  expect(screen.getByLabelText('Bố cục ảnh')).toHaveValue('grid');
  await user.click(screen.getByRole('button',{name:'Bỏ ảnh 1'}));
  expect(screen.getByLabelText('Mô tả ảnh 1')).toHaveValue('Hình thứ nhất');
  expect(screen.queryByLabelText('Mô tả ảnh 2')).not.toBeInTheDocument();
});
